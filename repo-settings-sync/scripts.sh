#!/usr/bin/env bash
# Copyright 2025 Simon Emms <simon@simonemms.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -eo pipefail

#############
# Variables #
#############

CMD="${1:-}"
TMP_DIR="/tmp/repo-settings-sync"

###########
# Scripts #
###########

mkdir -p "${TMP_DIR}"

apply_branch_protection() {
  TOKEN="${1}"
  REPO="${2}"
  SETTINGS="${3}"

  default_branch=$(get_default_branch "${TOKEN}" "${REPO}")

  # If on free tier and private repo, this will return a 403 error - accept and move on
  http_code=$(curl -o /tmp/apply_branch_output -w "%{http_code}" -L \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/branches/${default_branch}/protection" \
    -d "${SETTINGS}")

  if [ "${http_code}" -eq 200 ]; then
    echo "Settings successfully applied"
  elif [ "${http_code}" -eq 403 ]; then
    echo "Branch protection settings unavailable on private repos in the free tier"
  else
    echo "Failed to apply branch protection"
    cat /tmp/apply_branch_output
  fi
}

apply_repo_update() {
  TOKEN="${1}"
  REPO="${2}"
  SETTINGS="${3}"

  curl -sfL \
    -X PATCH \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}"\
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}" \
    -d "${SETTINGS}"
}

get_all_repos() {
  TOKEN="${1}"

  page=1
  finished=false

  dir="${TMP_DIR}/repos"
  rm -Rf "${dir}"
  mkdir -p "${dir}"

  until [ "${finished}" = "true" ]
  do
    result=$(curl -sfL \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/repos?page=${page}&affiliation=owner")

    count=$(echo "${result}" | jq '. | length')

    if [ "${count}" -eq 0 ]; then
      finished=true
    else
      echo "${result}" | jq -r > "${dir}/${page}.json"
    fi

    ((page++))
  done

  jq -s add ${dir}/*.json | jq -Mcr 'to_entries | map(select(.value.archived == false) | select(.value.disabled == false) | .value.full_name)'
}

get_default_branch() {
  TOKEN="${1}"
  REPO="${2}"

  # Get the default branch
  curl -sfL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}" | jq -r '.default_branch' || echo "main"
}

get_file_from_repo() {
  TOKEN="${1}"
  REPO="${2}"
  FILE_PATH="${3}"

  curl -sfL \
    -H "Accept: application/vnd.github.raw" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/contents/${FILE_PATH}"
}

get_required_status_checks() {
  TOKEN="${1}"
  REPO="${2}"

  default_branch=$(get_default_branch "${TOKEN}" "${REPO}")

  # This may return a 404 if branch not protected
  curl -sfL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/branches/${default_branch}/protection/required_status_checks"
}

############
# Commands #
############

case "${CMD}" in
  apply_branch_protection )
    apply_branch_protection "${2}" "${3}" "${4}" # Token, repo, settings
    ;;
  apply_repo_update )
    apply_repo_update "${2}" "${3}" "${4}" # Token, repo, settings
    ;;
  get_all_repos )
    get_all_repos "${2}" # Token
    ;;
  get_file_from_repo )
    get_file_from_repo "${2}" "${3}" "${4}" # Token, repo, file path
    ;;
  get_required_status_checks )
    get_required_status_checks "${2}" "${3}" # Token, repo
    ;;
  * )
    echo "Unknown command: ${CMD}"
    exit 1
    ;;
esac
