#!/bin/bash

# Copyright AppsCode Inc. and Contributors
#
# Licensed under the PolyForm Noncommercial License 1.0.0 and
# the AppsCode Free Trial License 1.0.0 (the "License"s);
# you may not use this file except in compliance with these Licenses.
# You may obtain a copy of these Licenses at
#
#  - https://github.com/appscode/licenses/raw/1.0.0/PolyForm-Noncommercial-1.0.0.md
#  - https://github.com/appscode/licenses/raw/1.0.0/AppsCode-Free-Trial-1.0.0.md
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eou pipefail

# Generated by render-gotpl. DO NOT EDIT.
# Make your desired changes in the files in the templates directory and run `make gen fmt`.

{{ template "catalogs.tpl" . }}
{{ template "common.tpl" }}
{{ template "script.tpl" }}
