{{/*
Expand the name of the chart.
*/}}
{{- define "statuspage-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "statuspage-exporter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "statuspage-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "statuspage-exporter.labels" -}}
helm.sh/chart: {{ include "statuspage-exporter.chart" . }}
{{ include "statuspage-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "statuspage-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "statuspage-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "statuspage-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "statuspage-exporter.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the vmProberSpec.url for the VMProbe
*/}}
{{- define "statuspage-exporter.vmProberSpecUrl" -}}
{{- if .Values.vmProbe.url }}
{{- .Values.vmProbe.url }}
{{- else }}
{{- printf "%s%s%s%s%s%d%s" "http://" (include "statuspage-exporter.fullname" .) "." .Release.Namespace ".svc.cluster.local:" (.Values.httpPort | int) "/probe" }}
{{- end }}
{{- end }}
