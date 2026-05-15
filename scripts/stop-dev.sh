#!/bin/bash
# Stop all development services

SESSION_NAME="sovereign-dev"

# Kill tmux session if it exists
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "Stopping ERA development session..."
    tmux kill-session -t $SESSION_NAME
    echo "✓ Tmux session stopped"
else
    echo "No active tmux session found"
fi

# Kill orphaned Metro bundler (port 8081) and Rails (port 3000) that
# may have outlived the tmux session
for port in 8081 3000; do
    PIDS=$(lsof -ti tcp:$port 2>/dev/null) || true
    if [ -n "$PIDS" ]; then
        echo "Killing process(es) on port $port (PID: $(echo $PIDS | tr '\n' ' '))..."
        kill $PIDS 2>/dev/null || true
    fi
done

echo "✓ Done"

