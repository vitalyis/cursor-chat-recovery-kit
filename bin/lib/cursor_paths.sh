#!/bin/bash

cursor_user_dir() {
    if [ -n "${CURSOR_USER_DIR:-}" ]; then
        printf '%s\n' "$CURSOR_USER_DIR"
        return
    fi

    if [ -n "${CURSOR_CONFIG_DIR:-}" ]; then
        printf '%s/User\n' "$CURSOR_CONFIG_DIR"
        return
    fi

    case "${OSTYPE:-}" in
        darwin*)
            printf '%s/Library/Application Support/Cursor/User\n' "$HOME"
            ;;
        linux*)
            printf '%s/Cursor/User\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
            ;;
        *)
            printf '%s/Library/Application Support/Cursor/User\n' "$HOME"
            ;;
    esac
}

cursor_workspace_storage_dir() {
    printf '%s/workspaceStorage\n' "$(cursor_user_dir)"
}

cursor_projects_dir() {
    printf '%s/.cursor/projects\n' "$HOME"
}

print_cursor_path_hint() {
    cat <<EOF
Resolved Cursor user dir: $(cursor_user_dir)
Resolved workspaceStorage: $(cursor_workspace_storage_dir)

If Cursor stores data elsewhere on your machine, rerun the command with:
  CURSOR_USER_DIR="/path/to/Cursor/User" <command>
or
  CURSOR_CONFIG_DIR="/path/to/Cursor" <command>
EOF
}
