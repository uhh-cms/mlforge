#!/usr/bin/env bash

setup_mlf_naf() {
    # Shorthand for "setup.sh naf" with good defaults.

    # get local variables
    local shell_is_zsh="$( [ -z "${ZSH_VERSION}" ] && echo "false" || echo "true" )"
    local this_file="$( ${shell_is_zsh} && echo "${(%):-%x}" || echo "${BASH_SOURCE[0]}" )"
    local this_dir="$( cd "$( dirname "${this_file}" )" && pwd )"

    # create a setup file if not already existing
    local setup_file="${this_dir}/.setups/naf.sh"
    if [ ! -f "${setup_file}" ]; then
        # some checks first
        local naf_user="$( whoami )"
        local naf_user_first_char="${naf_user:0:1}"
        local dust_dir="/nfs/dust/cms/user/${naf_user}"
        local xxl_dir="/afs/desy.de/user/${naf_user_first_char}/${naf_user}/xxl/af-cms"

        if [ ! -d "${dust_dir}" ] && [ ! -d "${xxl_dir}" ]; then
            >&2 echo "neither ${dust_dir} nor ${xxl_dir} existing"
            return "1"
        fi

        # create the file
        mkdir -p "$( dirname "${setup_file}" )"
        echo 'export CF_DATA="$MLF_BASE/data"' >> "${setup_file}"
        echo 'export CF_STORE_NAME="mlf_store"' >> "${setup_file}"
        if [ -d "${dust_dir}" ]; then
            echo "export CF_STORE_LOCAL=\"/nfs/dust/cms/user/${naf_user}/mlforge/${CF_STORE_NAME}\""  >> "${setup_file}"
        else
            echo "export CF_STORE_LOCAL=\"/afs/desy.de/user/${naf_user_first_char}/${naf_user}/xxl/af-cms/mlforge/${CF_STORE_NAME}\"" >> "${setup_file}"
        fi
        if [ -d "${xxl_dir}" ]; then
            echo "export CF_SOFTWARE_BASE=\"/afs/desy.de/user/${naf_user_first_char}/${naf_user}/xxl/af-cms/mlforge/software\"" >> "${setup_file}"
        else
            echo "export CF_SOFTWARE_BASE=\"/nfs/dust/cms/user/${naf_user}/mlforge/software\"" >> "${setup_file}"
        fi
        echo 'export CF_JOB_BASE="$CF_DATA/jobs"' >> "${setup_file}"
        echo 'export CF_TASK_NAMESPACE="mlf"' >> "${setup_file}"
        echo 'export CF_LOCAL_SCHEDULER="True"' >> "${setup_file}"
        echo 'export CF_SCHEDULER_HOST="127.0.0.1"' >> "${setup_file}"
        echo 'export CF_SCHEDULER_PORT="8082"' >> "${setup_file}"

    fi

    # source the main setup
    source "${this_dir}/setup.sh" "naf"
}

# entry point
setup_mlf_naf "$@"
