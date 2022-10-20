#!/usr/bin/env bash

setup_mlf() {
    # Runs the project setup, leading to a collection of environment variables starting with either
    #   - "CF_", for controlling behavior implemented by columnflow, or
    #   - "MLF_", for features provided by the mlforge repository itself.
    # Check the setup.sh in columnflow for documentation of the "CF_" variables. The purpose of all
    # "MLF_" variables is documented below.
    #
    # The setup also handles the installation of the software stack via virtual environments, and
    # optionally an interactive setup where the user can configure certain variables.
    #
    #
    # Arguments:
    #   1. The name of the setup. "default" (which is itself the default when no name is set)
    #      triggers a setup with good defaults, avoiding all queries to the user and the writing of
    #      a custom setup file. See "interactive_setup()" for more info.
    #
    #
    # Optinally preconfigured environment variables:
    #   None yet.
    #
    #
    # Variables defined by the setup and potentially required throughout the analysis:
    #   MLF_BASE
    #       The absolute mlforge base directory. Used to infer file locations relative to it.

    #
    # prepare local variables
    #

    local shell_is_zsh="$( [ -z "${ZSH_VERSION}" ] && echo "false" || echo "true" )"
    local this_file="$( ${shell_is_zsh} && echo "${(%):-%x}" || echo "${BASH_SOURCE[0]}" )"
    local this_dir="$( cd "$( dirname "${this_file}" )" && pwd )"
    local orig="${PWD}"
    local setup_name="${1:-default}"
    local setup_is_default="false"
    [ "${setup_name}" = "default" ] && setup_is_default="true"


    #
    # global variables
    # (MLF = mlforge, CF = columnflow)
    #

    # lang defaults
    export LANGUAGE="${LANGUAGE:-en_US.UTF-8}"
    export LANG="${LANG:-en_US.UTF-8}"
    export LC_ALL="${LC_ALL:-en_US.UTF-8}"

    # proxy
    export X509_USER_PROXY="${X509_USER_PROXY:-/tmp/x509up_u$( id -u )}"

    # start exporting variables
    export MLF_BASE="${this_dir}"
    export CF_BASE="${this_dir}/modules/columnflow"
    export CF_REPO_BASE="${MLF_BASE}"
    export CF_SETUP_NAME="${setup_name}"

    # load cf setup helpers
    CF_SKIP_SETUP="1" source "${CF_BASE}/setup.sh" "" || return "$?"

    # interactive setup
    if [ "${CF_REMOTE_JOB}" != "1" ]; then
        cf_setup_interactive_body() {
            # start querying for variables
            query CF_DATA "Local data directory" "\$MLF_BASE/data" "./data"
            query CF_STORE_NAME "Relative path used in store paths (see next queries)" "mlf_store"
            query CF_STORE_LOCAL "Default local output store" "\$CF_DATA/\$CF_STORE_NAME"
            query CF_SOFTWARE_BASE "Local directory for installing software" "\$CF_DATA/software"
            query CF_JOB_BASE "Local directory for storing job files" "\$CF_DATA/jobs"
            export_and_save CF_TASK_NAMESPACE "${CF_TASK_NAMESPACE:-mlf}"
            query CF_LOCAL_SCHEDULER "Use a local scheduler for law tasks" "True"
            if [ "${CF_LOCAL_SCHEDULER}" != "True" ]; then
                query CF_SCHEDULER_HOST "Address of a central scheduler for law tasks" "naf-cms15.desy.de"
                query CF_SCHEDULER_PORT "Port of a central scheduler for law tasks" "8082"
            else
                export_and_save CF_SCHEDULER_HOST "127.0.0.1"
                export_and_save CF_SCHEDULER_PORT "8082"
            fi
        }
        cf_setup_interactive "${CF_SETUP_NAME}" "${MLF_BASE}/.setups/${CF_SETUP_NAME}.sh" || return "$?"
    fi

    # continue the fixed setup
    export CF_CONDA_BASE="${CF_CONDA_BASE:-${CF_SOFTWARE_BASE}/conda}"
    export CF_VENV_BASE="${CF_VENV_BASE:-${CF_SOFTWARE_BASE}/venvs}"
    export CF_CMSSW_BASE="${CF_CMSSW_BASE:-${CF_SOFTWARE_BASE}/cmssw}"
    export CF_CI_JOB="$( [ "${GITHUB_ACTIONS}" = "true" ] && echo 1 || echo 0 )"

    # overwrite some variables in remote and CI jobs
    if [ "${CF_REMOTE_JOB}" = "1" ]; then
        export CF_WORKER_KEEP_ALIVE="false"
    elif [ "${CF_CI_JOB}" = "1" ]; then
        export CF_WORKER_KEEP_ALIVE="false"
    fi

    # some variable defaults
    export CF_WORKER_KEEP_ALIVE="${CF_WORKER_KEEP_ALIVE:-false}"
    export CF_SCHEDULER_HOST="${CF_SCHEDULER_HOST:-127.0.0.1}"
    export CF_SCHEDULER_PORT="${CF_SCHEDULER_PORT:-8082}"


    #
    # minimal local software setup
    #

    cf_setup_software_stack "${CF_SETUP_NAME}" || return "$?"

    # ammend paths that are not covered by the central cf setup
    export PATH="${MLF_BASE}/bin:${PATH}"
    export PYTHONPATH="${MLF_BASE}:${PYTHONPATH}"

    # initialze submodules
    if [ -d "${MLF_BASE}/.git" ]; then
        local m
        for m in $( ls -1q "${MLF_BASE}/modules" ); do
            cf_init_submodule "${MLF_BASE}" "modules/${m}"
        done
    fi


    #
    # law setup
    #

    export LAW_HOME="${MLF_BASE}/.law"
    export LAW_CONFIG_FILE="${MLF_BASE}/law.cfg"

    if which law &> /dev/null; then
        # source law's bash completion scipt
        source "$( law completion )" ""

        # silently index
        law index -q
    fi
}

main() {
    # Invokes the main action of this script, catches possible error codes and prints a message.

    # run the actual setup
    if setup_mlf "$@"; then
        cf_color green "Machine Learning Forge successfully setup"
        return "0"
    else
        local code="$?"
        cf_color red "setup failed with code ${code}"
        return "${code}"
    fi
}

# entry point
if [ "${MLF_SKIP_SETUP}" != "1" ]; then
    main "$@"
fi
