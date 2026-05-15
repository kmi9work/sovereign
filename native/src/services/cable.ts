import { CONFIG } from '../config';

const WS_URL = CONFIG.API_BASE_URL.replace(/^http/, 'ws') + '/cable';

interface SubscriptionCallbacks {
  received(data: unknown): void;
}

interface Subscription {
  unsubscribe(): void;
}

export interface Cable {
  subscribe(
    channel: string,
    params: Record<string, unknown>,
    callbacks: SubscriptionCallbacks,
  ): Subscription;
}

/**
 * Minimal Action Cable client using React Native's native WebSocket.
 *
 * Protocol:
 *   Client → {"command":"subscribe","identifier":"{\"channel\":\"...\"}"}
 *   Server → {"identifier":"{...}","type":"confirm_subscription"}
 *   Server → {"identifier":"{...}","message":{... actual data ...}}
 */
class ActionCableConsumer implements Cable {
  private ws: WebSocket | null = null;
  private subscriptions = new Map<string, SubscriptionCallbacks>();
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private shouldReconnect = false;
  private url: string;

  constructor(url: string) {
    this.url = url;
  }

  subscribe(
    channel: string,
    params: Record<string, unknown>,
    callbacks: SubscriptionCallbacks,
  ): Subscription {
    const identifier = JSON.stringify({ channel, ...params });
    this.subscriptions.set(identifier, callbacks);
    this.shouldReconnect = true;
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ command: 'subscribe', identifier }));
    } else {
      this.connect();
    }
    return { unsubscribe: () => this.unsubscribe(identifier) };
  }

  private unsubscribe(identifier: string): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({ command: 'unsubscribe', identifier }));
    }
    this.subscriptions.delete(identifier);
    if (this.subscriptions.size === 0) {
      this.shouldReconnect = false;
      this.cleanup();
    }
  }

  private connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN || this.ws?.readyState === WebSocket.CONNECTING) {
      return;
    }

    const ws = new WebSocket(this.url);
    this.ws = ws;

    ws.onopen = () => {
      this.subscriptions.forEach((_, identifier) => {
        ws.send(JSON.stringify({ command: 'subscribe', identifier }));
      });
    };

    ws.onmessage = (event: WebSocketMessageEvent) => {
      try {
        const data = JSON.parse(event.data);
        if (!data.identifier || !data.message) return;
        const cb = this.subscriptions.get(data.identifier);
        cb?.received(data.message);
      } catch {
        // ignore malformed messages
      }
    };

    ws.onclose = () => {
      if (this.ws === ws) this.ws = null;
      if (this.shouldReconnect) {
        this.reconnectTimer = setTimeout(() => this.connect(), 1000);
      }
    };

    ws.onerror = () => {
      // onclose always fires after onerror
    };
  }

  private cleanup(): void {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    this.shouldReconnect = false;
    if (this.ws) {
      this.ws.onclose = null;
      this.ws.close();
      this.ws = null;
    }
  }
}

export const cable: Cable = new ActionCableConsumer(WS_URL);
