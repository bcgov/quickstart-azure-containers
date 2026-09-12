#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${SCRIPT_DIR}/initial-azure-setup.sh"

(
    set -- \
        --resource-group test-networking \
        --identity-name test-identity \
        --github-repo bcgov/quickstart-azure-containers \
        --environment dev \
        --dry-run

    source <(sed '/^# Execute the main function with all provided arguments/,$d' "$SCRIPT")

    gh() {
        case "${1:-}" in
            auth)
                return 0
                ;;
            api)
                case "${OIDC_CASE:-}" in
                    missing-flag)
                        local jq_filter=""
                        while [[ $# -gt 0 ]]; do
                            if [[ "$1" == "--jq" ]]; then
                                jq_filter="${2:-}"
                                break
                            fi
                            shift
                        done

                        if [[ "$jq_filter" == *"// false"* ]]; then
                            printf '%s\n' $'false\trepo:bcgov/quickstart-azure-containers'
                        else
                            printf '%s\n' $'\trepo:bcgov/quickstart-azure-containers'
                        fi
                        ;;
                    immutable)
                        printf '%s\n' $'true\trepo:bcgov@916280/quickstart-azure-containers@1004724015'
                        ;;
                    *)
                        printf 'Unexpected OIDC test case: %s\n' "${OIDC_CASE:-unset}" >&2
                        return 1
                        ;;
                esac
                ;;
            *)
                return 1
                ;;
        esac
    }

    OIDC_CASE=missing-flag
    unset SUBJECT
    set +e
    resolve_github_oidc_subject
    resolve_rc=$?
    set -e
    if [[ $resolve_rc -ne 0 ]]; then
        printf 'Expected missing use_immutable_subject to be handled by the resolver.\n' >&2
        exit 1
    fi

    expected_legacy_subject="repo:bcgov/quickstart-azure-containers:environment:dev"
    if [[ "$SUBJECT" != "$expected_legacy_subject" ]]; then
        printf 'Expected legacy OIDC subject, got: %s\n' "$SUBJECT" >&2
        exit 1
    fi

    OIDC_CASE=immutable
    resolve_github_oidc_subject

    captured_command=""
    execute_command() {
        captured_command="$1"
    }

    create_federated_credentials

    expected_subject="repo:bcgov@916280/quickstart-azure-containers@1004724015:environment:dev"
    if [[ "$captured_command" != *"--subject '$expected_subject'"* ]]; then
        printf 'Expected immutable OIDC subject in Azure command, got:\n%s\n' "$captured_command" >&2
        exit 1
    fi
)

(
    set -- \
        --resource-group test-networking \
        --identity-name test-identity \
        --github-repo bcgov/quickstart-azure-containers \
        --environment dev \
        --dry-run

    source <(sed '/^# Execute the main function with all provided arguments/,$d' "$SCRIPT")

    check_and_install_tools() {
        :
    }

    az() {
        printf 'test\n'
    }

    gh() {
        case "${1:-}" in
            auth)
                return 0
                ;;
            api)
                printf '%s\n' $'true\trepo:bcgov@916280/quickstart-azure-containers@1004724015'
                ;;
            *)
                return 1
                ;;
        esac
    }

    OIDC_SUBJECT_RESOLVED=false
    create_managed_identity() {
        if [[ "$OIDC_SUBJECT_RESOLVED" != "true" ]]; then
            printf 'GitHub OIDC API was not validated before Azure mutation.\n' >&2
            exit 1
        fi
    }

    get_identity_details() { :; }
    add_to_security_group() { :; }
    assign_key_vault_secrets_officer_role() { :; }
    assign_key_vault_data_access_administrator_role() { :; }
    create_terraform_storage() { :; }
    assign_storage_roles() { :; }
    create_federated_credentials() { :; }
    create_github_secrets() { :; }
    verify_setup() { :; }

    main
)

printf 'OIDC subject tests passed.\n'