#!/usr/bin/env python3
"""
Export Claude Code session to readable .log file
Usage: python3 export_session.py /path/to/project [output.log]
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

def get_session_dir(project_path):
    """Convert project path to Claude session directory name"""
    # Claude uses dashes for slashes and underscores
    session_name = project_path.replace('/', '-').replace('_', '-')
    if not session_name.startswith('-'):
        session_name = '-' + session_name
    return Path.home() / '.claude' / 'projects' / session_name

def find_latest_session(session_dir):
    """Find the most recently modified session file"""
    if not session_dir.exists():
        return None

    session_files = [f for f in session_dir.glob('*.jsonl')
                     if not f.name.startswith('agent-')]

    if not session_files:
        return None

    return max(session_files, key=lambda f: f.stat().st_mtime)

def extract_text_content(content):
    """Extract readable text from message content"""
    if isinstance(content, str):
        return content

    if isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get('type') == 'text':
                    texts.append(block.get('text', ''))
                elif block.get('type') == 'tool_use':
                    tool_name = block.get('name', 'unknown')
                    texts.append(f"[Tool: {tool_name}]")
                elif block.get('type') == 'tool_result':
                    texts.append("[Tool Result]")
            elif isinstance(block, str):
                texts.append(block)
        return '\n'.join(texts)

    return str(content)

def export_session(project_path, output_path=None):
    """Export session to log file"""
    session_dir = get_session_dir(project_path)
    session_file = find_latest_session(session_dir)

    if not session_file:
        print(f"No session found for: {project_path}")
        print(f"Looked in: {session_dir}")
        return None

    print(f"Found session: {session_file.name}")

    # Parse session
    messages = []
    with open(session_file) as f:
        for line in f:
            try:
                entry = json.loads(line)
                entry_type = entry.get('type')

                if entry_type in ('user', 'assistant'):
                    timestamp = entry.get('timestamp', '')
                    message = entry.get('message', {})
                    role = message.get('role', entry_type)
                    content = message.get('content', '')

                    text = extract_text_content(content)
                    if text.strip():
                        messages.append({
                            'timestamp': timestamp,
                            'role': role.upper(),
                            'content': text
                        })
            except json.JSONDecodeError:
                continue

    # Generate output
    if output_path is None:
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_path = Path(project_path) / f'session_log_{timestamp}.log'

    with open(output_path, 'w') as f:
        f.write(f"# Claude Code Session Log\n")
        f.write(f"# Project: {project_path}\n")
        f.write(f"# Session: {session_file.name}\n")
        f.write(f"# Exported: {datetime.now().isoformat()}\n")
        f.write(f"# Messages: {len(messages)}\n")
        f.write("=" * 80 + "\n\n")

        for msg in messages:
            ts = msg['timestamp'][:19].replace('T', ' ') if msg['timestamp'] else ''
            f.write(f"[{ts}] {msg['role']}:\n")
            f.write("-" * 40 + "\n")
            f.write(msg['content'])
            f.write("\n\n" + "=" * 80 + "\n\n")

    print(f"Exported {len(messages)} messages to: {output_path}")
    return output_path

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 export_session.py /path/to/project [output.log]")
        sys.exit(1)

    project = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else None

    export_session(project, output)
