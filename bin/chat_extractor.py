#!/usr/bin/env python3

import sys
import json
import re
from datetime import datetime

def extract_chats(data_string, workspace_id):
    """Extract chat conversations from Cursor chat data"""
    try:
        if not data_string.strip():
            return "No chat data found", []
        
        chat_data = json.loads(data_string)
        
        # Extract tabs (individual chat conversations)
        tabs = chat_data.get('tabs', [])
        
        if not tabs:
            return "No chat conversations found", []
        
        output = []
        chat_index = []  # For the index log
        output.append(f'Found {len(tabs)} chat conversations\n')
        
        for i, tab in enumerate(tabs[:10]):  # Process up to 10 most recent chats
            tab_id = tab.get('tabId', f'chat_{i}')
            chat_title = tab.get('chatTitle', 'Untitled Chat')
            bubbles = tab.get('bubbles', [])
            
            if not bubbles:
                continue
            
            # Add to chat index
            chat_index.append({
                'index': i + 1,
                'title': chat_title,
                'tab_id': tab_id,
                'message_count': len(bubbles),
                'workspace_id': workspace_id
            })
            
            output.append(f'\n## Chat: {chat_title}')
            output.append(f'**Tab ID:** {tab_id}  ')
            output.append(f'**Messages:** {len(bubbles)}  ')
            output.append(f'**Extracted:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  ')
            output.append('')
            
            # Process conversation bubbles
            for j, bubble in enumerate(bubbles[:30]):  # Limit to first 30 messages
                bubble_type = bubble.get('type', 'unknown')
                text = bubble.get('text', '')
                
                # Handle different bubble types
                if bubble_type == 'user':
                    output.append('### 👤 User:')
                elif bubble_type in ['assistant', 'ai']:
                    output.append('### 🤖 Assistant:')
                else:
                    # Try to detect if it's user or assistant based on content
                    if 'codeblock' in bubble or 'text' in bubble:
                        # Check if it looks like assistant response
                        if any(word in str(bubble).lower() for word in ['i can help', 'let me', "here's", 'you can', 'to do this']):
                            output.append('### 🤖 Assistant:')
                        else:
                            output.append('### 👤 User:')
                    else:
                        output.append(f'### 🔍 {bubble_type.title()}:')
                
                # Extract and clean text content
                if text:
                    # Clean up text and format for markdown
                    clean_text = str(text).replace('\n', '\n> ')
                    
                    # Limit length to avoid huge outputs
                    if len(clean_text) > 1500:
                        clean_text = clean_text[:1500] + '\n> ...(message truncated)'
                    
                    output.append(f'> {clean_text}')
                elif 'codeblock' in bubble:
                    # Handle code blocks
                    codeblock = bubble.get('codeblock', {})
                    language = codeblock.get('language', '')
                    code = codeblock.get('text', '')
                    
                    if code:
                        output.append(f'> ```{language}')
                        # Limit code length
                        if len(code) > 1000:
                            code = code[:1000] + '\n# ...(code truncated)'
                        output.append(f'> {code.replace(chr(10), chr(10) + "> ")}')
                        output.append('> ```')
                
                output.append('')  # Empty line between messages
                
                # Stop if we've shown enough of this conversation
                if j >= 29:
                    output.append('> ...(remaining messages truncated)')
                    output.append('')
                    break
            
            output.append('---')
            output.append('')
            
            # Stop processing if we've shown enough chats
            if i >= 9:
                output.append('\n> ...(remaining chats not shown - use specific backup extraction for full data)')
                break
        
        return '\n'.join(output), chat_index
        
    except json.JSONDecodeError as e:
        return f'Error parsing JSON: {e}', []
    except Exception as e:
        return f'Error processing chat data: {e}', []

if __name__ == "__main__":
    # Read data from stdin
    data = sys.stdin.read()
    workspace_id = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    output_format = sys.argv[2] if len(sys.argv) > 2 else "markdown"
    
    result, chat_index = extract_chats(data, workspace_id)
    
    if output_format == "index":
        # Output chat index as JSON for the shell script to process
        import json
        print(json.dumps(chat_index))
    else:
        # Output markdown content
        print(result)
