import { useEffect, useRef } from 'react';
import { cable } from '../services/cable';

export function useCable<T>(
  channel: string,
  params: Record<string, unknown>,
  onReceived: (data: T) => void,
) {
  const savedCallback = useRef(onReceived);

  useEffect(() => {
    savedCallback.current = onReceived;
  }, [onReceived]);

  useEffect(() => {
    const subscription = cable.subscribe(channel, params, {
      received(data: unknown) {
        savedCallback.current(data as T);
      },
    });

    return () => {
      subscription.unsubscribe();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [channel, JSON.stringify(params)]);
}
