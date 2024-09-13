{{/* vim: set filetype=mustache: */}}

{{- define "cadence.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cadence.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "cadence.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cadence.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
