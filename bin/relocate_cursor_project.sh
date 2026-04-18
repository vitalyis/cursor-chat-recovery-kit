#!/bin/bash
set -euo pipefail

CURSOR_USER_DIR="${HOME}/Library/Application Support/Cursor/User"
WORKSPACE_STORAGE_DIR="${CURSOR_USER_DIR}/workspaceStorage"
CURSOR_PROJECTS_DIR="${HOME}/.cursor/projects"
BACKUP_ROOT="${HOME}/cursor_backups/project_relocations"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

blue() { printf "\033[0;34m%s\033[0m\n" "$*"; }
green() { printf "\033[0;32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$*"; }
red() { printf "\033[0;31m%s\033[0m\n" "$*"; }

usage() {
    cat <<'EOF'
Cursor Project Relocation Tool
==============================

Project-aware Cursor backup and git worktree relocation for repo moves.

Commands:
  backup <project_path>
      Back up Cursor workspace state, .cursor/projects transcript/tool logs,
      and git worktree metadata for one project.

  preflight <old_path> <new_path> [--worktree-root DIR]
      Show the resources that would be backed up or moved.

  move <old_path> <new_path> [--worktree-root DIR] [--no-symlink]
       [--skip-full-backup] [--skip-project-dir-copy] [--apply]
      Relocate a git-backed project, move linked worktrees, and preserve
      Cursor state. Runs as a dry-run unless --apply is provided.

Notes:
  - Close Cursor before running `move`.
  - `move` creates a project-scoped backup and, by default, also runs the
    existing full Cursor export script.
  - By default the old repo path is recreated as a symlink to the new path
    for compatibility with existing Cursor workspace bindings.
EOF
}

json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

resolve_existing_dir() {
    local path="$1"
    if [[ ! -d "$path" ]]; then
        red "❌ Directory not found: $path"
        exit 1
    fi
    (cd "$path" && pwd -P)
}

resolve_target_path() {
    local path="$1"
    if [[ "$path" = /* ]]; then
        printf '%s\n' "$path"
    else
        printf '%s/%s\n' "$(pwd -P)" "$path"
    fi
}

slugify_path() {
    printf '%s' "$1" | sed \
        -e 's#^/##' \
        -e 's#[[:space:]/.]#-#g' \
        -e 's#[^A-Za-z0-9_-]#-#g' \
        -e 's#--*#-#g' \
        -e 's#-$##'
}

file_uri_path() {
    printf '%s' "$1" | sed -e 's/%/%25/g' -e 's/ /%20/g' -e 's/#/%23/g'
}

ensure_cursor_storage() {
    if [[ ! -d "$WORKSPACE_STORAGE_DIR" ]]; then
        red "❌ Cursor workspaceStorage not found: $WORKSPACE_STORAGE_DIR"
        exit 1
    fi
}

ensure_git_repo() {
    local repo="$1"
    if ! git -C "$repo" rev-parse --show-toplevel >/dev/null 2>&1; then
        red "❌ Not a git repository: $repo"
        exit 1
    fi
}

check_cursor_closed() {
    if pgrep -x "Cursor" >/dev/null 2>&1; then
        red "❌ Cursor is still running. Close it before relocation."
        exit 1
    fi
}

append_array() {
    local __name="$1"
    local __value="$2"
    eval "$__name[\${#$__name[@]}]=\"\$__value\""
}

discover_workspace_ids() {
    local project_path="$1"
    local encoded_path
    local workspace_file
    local folder_path

    encoded_path="$(file_uri_path "$project_path")"
    ensure_cursor_storage

    for workspace_file in "$WORKSPACE_STORAGE_DIR"/*/workspace.json; do
        [[ -f "$workspace_file" ]] || continue
        folder_path="$(sed -n 's/.*"folder":[[:space:]]*"file:\/\/\(.*\)".*/\1/p' "$workspace_file" | sed 's/%20/ /g' | sed 's/%23/#/g' | sed 's/%25/%/g')"
        if [[ "$folder_path" = "$project_path" || "$folder_path" = "$project_path/"* ]]; then
            basename "$(dirname "$workspace_file")"
            continue
        fi
        if grep -Fq "file://${encoded_path}" "$workspace_file"; then
            basename "$(dirname "$workspace_file")"
        fi
    done | sort -u
}

discover_cursor_project_dirs() {
    local project_path="$1"
    local project_slug
    local candidate
    local found=0

    [[ -d "$CURSOR_PROJECTS_DIR" ]] || return 0

    project_slug="$(slugify_path "$project_path")"
    for candidate in "$CURSOR_PROJECTS_DIR"/*; do
        [[ -d "$candidate" ]] || continue
        case "$(basename "$candidate")" in
            "$project_slug"|"$project_slug"-*)
                printf '%s\n' "$candidate"
                found=1
                ;;
        esac
    done

    if [[ "$found" -eq 0 ]] && command -v rg >/dev/null 2>&1; then
        rg -l --fixed-strings "$project_path" "$CURSOR_PROJECTS_DIR" 2>/dev/null \
            | sed 's#/[^/]*$##' | sort -u
    fi
}

collect_worktrees() {
    local repo="$1"
    git -C "$repo" worktree list --porcelain | sed -n 's/^worktree //p'
}

git_status_summary() {
    local repo="$1"
    git -C "$repo" status --short 2>/dev/null || true
}

default_worktree_root() {
    local new_path="$1"
    local project_name project_parent projects_root
    project_name="$(basename "$new_path")"
    project_parent="$(dirname "$new_path")"
    projects_root="$(dirname "$project_parent")"
    printf '%s/Worktrees/%s\n' "$projects_root" "$project_name"
}

worktree_target_path() {
    local old_repo="$1"
    local old_worktree="$2"
    local new_repo="$3"
    local worktree_root="$4"
    local repo_name worktree_name suffix

    repo_name="$(basename "$old_repo")"
    worktree_name="$(basename "$old_worktree")"

    if [[ "$old_worktree" = "$old_repo" ]]; then
        printf '%s\n' "$new_repo"
        return
    fi

    if [[ "$worktree_name" = "$repo_name"-* ]]; then
        suffix="${worktree_name#${repo_name}-}"
    else
        suffix="$worktree_name"
    fi

    printf '%s/%s\n' "$worktree_root" "$suffix"
}

worktree_admin_name() {
    local worktree_path="$1"
    local gitfile gitdir_path

    gitfile="${worktree_path}/.git"
    if [[ ! -f "$gitfile" ]]; then
        return 0
    fi

    gitdir_path="$(sed -n 's/^gitdir: //p' "$gitfile")"
    basename "$gitdir_path"
}

write_manifest() {
    local backup_dir="$1"
    local project_path="$2"
    local repo_root="$3"
    local created_at="$4"
    shift 4

    local workspace_ids=()
    local cursor_dirs=()
    local worktrees=()
    local section=""
    local value i

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workspace-ids) section="workspace" ;;
            --cursor-projects) section="cursor" ;;
            --worktrees) section="worktree" ;;
            --next) section="" ;;
            *)
                case "$section" in
                    workspace) append_array workspace_ids "$1" ;;
                    cursor) append_array cursor_dirs "$1" ;;
                    worktree) append_array worktrees "$1" ;;
                esac
                ;;
        esac
        shift
    done

    {
        printf 'Project relocation backup\n'
        printf '=========================\n'
        printf 'Created at: %s\n' "$created_at"
        printf 'Project path: %s\n' "$project_path"
        printf 'Repo root: %s\n' "$repo_root"
        printf '\nWorkspace IDs:\n'
        if [[ ${#workspace_ids[@]} -eq 0 ]]; then
            printf '  - none\n'
        else
            for value in "${workspace_ids[@]}"; do
                printf '  - %s\n' "$value"
            done
        fi
        printf '\nCursor project dirs:\n'
        if [[ ${#cursor_dirs[@]} -eq 0 ]]; then
            printf '  - none\n'
        else
            for value in "${cursor_dirs[@]}"; do
                printf '  - %s\n' "$value"
            done
        fi
        printf '\nGit worktrees:\n'
        if [[ ${#worktrees[@]} -eq 0 ]]; then
            printf '  - none\n'
        else
            for value in "${worktrees[@]}"; do
                printf '  - %s\n' "$value"
            done
        fi
    } > "${backup_dir}/manifest.txt"

    {
        printf '{\n'
        printf '  "created_at": "%s",\n' "$(json_escape "$created_at")"
        printf '  "project_path": "%s",\n' "$(json_escape "$project_path")"
        printf '  "repo_root": "%s",\n' "$(json_escape "$repo_root")"
        printf '  "workspace_ids": ['
        for ((i=0; i<${#workspace_ids[@]}; i++)); do
            [[ $i -gt 0 ]] && printf ', '
            printf '"%s"' "$(json_escape "${workspace_ids[$i]}")"
        done
        printf '],\n'
        printf '  "cursor_project_dirs": ['
        for ((i=0; i<${#cursor_dirs[@]}; i++)); do
            [[ $i -gt 0 ]] && printf ', '
            printf '"%s"' "$(json_escape "${cursor_dirs[$i]}")"
        done
        printf '],\n'
        printf '  "git_worktrees": ['
        for ((i=0; i<${#worktrees[@]}; i++)); do
            [[ $i -gt 0 ]] && printf ', '
            printf '"%s"' "$(json_escape "${worktrees[$i]}")"
        done
        printf ']\n'
        printf '}\n'
    } > "${backup_dir}/manifest.json"
}

create_project_backup() {
    local project_path="$1"
    local backup_dir="$2"
    local repo_root created_at workspace_id project_dir worktree
    local workspace_ids=()
    local cursor_dirs=()
    local worktrees=()

    repo_root="$(git -C "$project_path" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$project_path")"
    created_at="$(date '+%Y-%m-%d %H:%M:%S')"

    mkdir -p "$backup_dir/workspaceStorage" "$backup_dir/cursor_projects" "$backup_dir/metadata"

    while IFS= read -r workspace_id; do
        [[ -n "$workspace_id" ]] || continue
        append_array workspace_ids "$workspace_id"
        cp -R "${WORKSPACE_STORAGE_DIR}/${workspace_id}" "${backup_dir}/workspaceStorage/"
    done < <(discover_workspace_ids "$project_path")

    while IFS= read -r project_dir; do
        [[ -n "$project_dir" ]] || continue
        append_array cursor_dirs "$project_dir"
        cp -R "$project_dir" "${backup_dir}/cursor_projects/"
    done < <(discover_cursor_project_dirs "$project_path")

    if git -C "$project_path" rev-parse --show-toplevel >/dev/null 2>&1; then
        while IFS= read -r worktree; do
            [[ -n "$worktree" ]] || continue
            append_array worktrees "$worktree"
        done < <(collect_worktrees "$project_path")
        git -C "$project_path" worktree list --porcelain > "${backup_dir}/metadata/git_worktree_list.txt"
        git -C "$project_path" remote -v > "${backup_dir}/metadata/git_remotes.txt" || true
        git -C "$project_path" branch --show-current > "${backup_dir}/metadata/current_branch.txt" || true
        git_status_summary "$project_path" > "${backup_dir}/metadata/git_status.txt"
    fi

    write_manifest \
        "$backup_dir" \
        "$project_path" \
        "$repo_root" \
        "$created_at" \
        --workspace-ids "${workspace_ids[@]}" --next \
        --cursor-projects "${cursor_dirs[@]}" --next \
        --worktrees "${worktrees[@]}"

    green "✅ Project backup created: $backup_dir"
}

run_full_cursor_backup() {
    local apply="$1"
    local export_script="${SCRIPT_DIR}/export_cursor_chats.sh"

    if [[ ! -f "$export_script" ]]; then
        yellow "⚠️  Full Cursor export script not found: $export_script"
        return
    fi

    if [[ "$apply" -eq 1 ]]; then
        blue "📦 Running full Cursor backup..."
        bash "$export_script"
    else
        printf '[dry-run] bash %q\n' "$export_script"
    fi
}

copy_cursor_project_dirs_to_new_slug() {
    local old_path="$1"
    local new_path="$2"
    local apply="$3"
    local old_slug new_slug old_dir new_dir suffix
    local project_dirs=()

    [[ -d "$CURSOR_PROJECTS_DIR" ]] || return 0

    old_slug="$(slugify_path "$old_path")"
    new_slug="$(slugify_path "$new_path")"

    while IFS= read -r old_dir; do
        [[ -n "$old_dir" ]] || continue
        append_array project_dirs "$old_dir"
    done < <(discover_cursor_project_dirs "$old_path")

    for old_dir in "${project_dirs[@]}"; do
        suffix="${old_dir##*/}"
        suffix="${suffix#$old_slug}"
        new_dir="${CURSOR_PROJECTS_DIR}/${new_slug}${suffix}"
        if [[ -e "$new_dir" ]]; then
            yellow "⚠️  Skipping existing Cursor project dir: $new_dir"
            continue
        fi
        if [[ "$apply" -eq 1 ]]; then
            mkdir -p "$CURSOR_PROJECTS_DIR"
            cp -R "$old_dir" "$new_dir"
        else
            printf '[dry-run] cp -R %q %q\n' "$old_dir" "$new_dir"
        fi
    done
}

show_preflight() {
    local old_path="$1"
    local new_path="$2"
    local worktree_root="$3"
    local workspace_id project_dir worktree target_path git_root

    blue "🔎 Preflight summary"
    printf 'Old path: %s\n' "$old_path"
    printf 'New path: %s\n' "$new_path"
    printf 'Worktree root: %s\n' "$worktree_root"
    printf '\nWorkspace IDs:\n'
    while IFS= read -r workspace_id; do
        [[ -n "$workspace_id" ]] || continue
        printf '  - %s\n' "$workspace_id"
    done < <(discover_workspace_ids "$old_path")

    printf '\nCursor project dirs:\n'
    while IFS= read -r project_dir; do
        [[ -n "$project_dir" ]] || continue
        printf '  - %s\n' "$project_dir"
    done < <(discover_cursor_project_dirs "$old_path")

    git_root="$(git -C "$old_path" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$git_root" ]]; then
        printf '\nGit worktrees:\n'
        while IFS= read -r worktree; do
            [[ -n "$worktree" ]] || continue
            target_path="$(worktree_target_path "$old_path" "$worktree" "$new_path" "$worktree_root")"
            printf '  - %s -> %s\n' "$worktree" "$target_path"
        done < <(collect_worktrees "$old_path")
        printf '\nGit status:\n'
        git_status_summary "$old_path"
    else
        printf '\nGit worktrees: project is not a git repo\n'
    fi
}

move_project() {
    local old_path="$1"
    local new_path="$2"
    local worktree_root="$3"
    local keep_symlink="$4"
    local full_backup="$5"
    local copy_project_dirs="$6"
    local apply="$7"
    local backup_dir old_slug parent_dir worktree target_path admin_name
    local worktrees=()
    local worktree_targets=()
    local worktree_admins=()
    local i

    ensure_git_repo "$old_path"

    if [[ -e "$new_path" ]]; then
        red "❌ Target already exists: $new_path"
        exit 1
    fi

    while IFS= read -r worktree; do
        [[ -n "$worktree" ]] || continue
        append_array worktrees "$worktree"
        append_array worktree_targets "$(worktree_target_path "$old_path" "$worktree" "$new_path" "$worktree_root")"
        append_array worktree_admins "$(worktree_admin_name "$worktree")"
    done < <(collect_worktrees "$old_path")

    for ((i=1; i<${#worktrees[@]}; i++)); do
        target_path="${worktree_targets[$i]}"
        if [[ -e "$target_path" ]]; then
            red "❌ Worktree target already exists: $target_path"
            exit 1
        fi
    done

    old_slug="$(slugify_path "$old_path")"
    backup_dir="${BACKUP_ROOT}/$(date '+%Y%m%d_%H%M%S')_${old_slug}"

    blue "📦 Project backup directory: $backup_dir"
    if [[ "$apply" -eq 1 ]]; then
        check_cursor_closed
        mkdir -p "$BACKUP_ROOT"
        create_project_backup "$old_path" "$backup_dir"
        if [[ "$full_backup" -eq 1 ]]; then
            run_full_cursor_backup 1
        fi
    else
        printf '[dry-run] create project backup at %q\n' "$backup_dir"
        if [[ "$full_backup" -eq 1 ]]; then
            run_full_cursor_backup 0
        fi
    fi

    for ((i=1; i<${#worktrees[@]}; i++)); do
        parent_dir="$(dirname "${worktree_targets[$i]}")"
        if [[ "$apply" -eq 1 ]]; then
            mkdir -p "$parent_dir"
            git -C "$old_path" worktree move "${worktrees[$i]}" "${worktree_targets[$i]}"
        else
            printf '[dry-run] git -C %q worktree move %q %q\n' "$old_path" "${worktrees[$i]}" "${worktree_targets[$i]}"
        fi
    done

    parent_dir="$(dirname "$new_path")"
    if [[ "$apply" -eq 1 ]]; then
        mkdir -p "$parent_dir"
        mv "$old_path" "$new_path"
    else
        printf '[dry-run] mv %q %q\n' "$old_path" "$new_path"
    fi

    if [[ "$keep_symlink" -eq 1 ]]; then
        if [[ "$apply" -eq 1 ]]; then
            ln -s "$new_path" "$old_path"
        else
            printf '[dry-run] ln -s %q %q\n' "$new_path" "$old_path"
        fi
    fi

    for ((i=1; i<${#worktrees[@]}; i++)); do
        [[ -n "${worktree_admins[$i]}" ]] || continue
        if [[ "$apply" -eq 1 ]]; then
            printf 'gitdir: %s/.git/worktrees/%s\n' "$new_path" "${worktree_admins[$i]}" > "${worktree_targets[$i]}/.git"
        else
            printf '[dry-run] rewrite %q/.git -> %q/.git/worktrees/%q\n' "${worktree_targets[$i]}" "$new_path" "${worktree_admins[$i]}"
        fi
    done

    if [[ "$copy_project_dirs" -eq 1 ]]; then
        copy_cursor_project_dirs_to_new_slug "$old_path" "$new_path" "$apply"
    fi

    if [[ "$apply" -eq 1 ]]; then
        green "✅ Project relocation completed."
        yellow "ℹ️  Open the repo from the new path in Cursor. If it creates a fresh workspace ID, use restore_chat_history.sh auto to seed the new workspace from the old path."
    else
        green "✅ Dry-run completed."
    fi
}

main() {
    local command="${1:-}"
    shift || true

    local old_path new_path worktree_root keep_symlink full_backup copy_project_dirs apply

    case "$command" in
        backup)
            old_path="${1:-}"
            [[ -n "$old_path" ]] || { usage; exit 1; }
            old_path="$(resolve_existing_dir "$old_path")"
            mkdir -p "$BACKUP_ROOT"
            create_project_backup "$old_path" "${BACKUP_ROOT}/$(date '+%Y%m%d_%H%M%S')_$(slugify_path "$old_path")"
            ;;
        preflight)
            old_path="${1:-}"
            new_path="${2:-}"
            [[ -n "$old_path" && -n "$new_path" ]] || { usage; exit 1; }
            shift 2 || true
            worktree_root=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --worktree-root)
                        worktree_root="$2"
                        shift 2
                        ;;
                    *)
                        red "❌ Unknown option: $1"
                        exit 1
                        ;;
                esac
            done
            old_path="$(resolve_existing_dir "$old_path")"
            new_path="$(resolve_target_path "$new_path")"
            ensure_git_repo "$old_path"
            if [[ -z "$worktree_root" ]]; then
                worktree_root="$(default_worktree_root "$new_path")"
            fi
            show_preflight "$old_path" "$new_path" "$worktree_root"
            ;;
        move)
            old_path="${1:-}"
            new_path="${2:-}"
            [[ -n "$old_path" && -n "$new_path" ]] || { usage; exit 1; }
            shift 2 || true
            worktree_root=""
            keep_symlink=1
            full_backup=1
            copy_project_dirs=1
            apply=0

            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --worktree-root)
                        worktree_root="$2"
                        shift 2
                        ;;
                    --no-symlink)
                        keep_symlink=0
                        shift
                        ;;
                    --skip-full-backup)
                        full_backup=0
                        shift
                        ;;
                    --skip-project-dir-copy)
                        copy_project_dirs=0
                        shift
                        ;;
                    --apply)
                        apply=1
                        shift
                        ;;
                    *)
                        red "❌ Unknown option: $1"
                        exit 1
                        ;;
                esac
            done

            old_path="$(resolve_existing_dir "$old_path")"
            new_path="$(resolve_target_path "$new_path")"
            if [[ -z "$worktree_root" ]]; then
                worktree_root="$(default_worktree_root "$new_path")"
            fi

            move_project "$old_path" "$new_path" "$worktree_root" "$keep_symlink" "$full_backup" "$copy_project_dirs" "$apply"
            ;;
        help|--help|-h|"")
            usage
            ;;
        *)
            red "❌ Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
