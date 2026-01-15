#!/usr/bin/env python3

import sys
import json

def format_chat_index(data):
    """Format chat index data for the log file"""
    try:
        chat_list = json.loads(data)
        if not chat_list:
            return "No chats found"
        
        output = []
        output.append(f"Found {len(chat_list)} chat conversations:")
        output.append("-" * 50)
        
        for chat in chat_list:
            index = chat.get('index', '?')
            title = chat.get('title', 'Untitled Chat')
            msgs = chat.get('message_count', 0)
            
            # Truncate long titles
            if len(title) > 55:
                title = title[:55] + "..."
            
            output.append(f"{index:2d}. {title} ({msgs} messages)")
        
        return '\n'.join(output)
        
    except json.JSONDecodeError:
        return "Error: Invalid JSON data"
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    data = sys.stdin.read().strip()
    result = format_chat_index(data)
    print(result)