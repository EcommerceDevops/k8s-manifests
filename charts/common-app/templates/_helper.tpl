{{/*
Define helpers estándar para generar nombres y etiquetas.
*/}}

{{/*
Genera el nombre del chart.
*/}}
{{- define "common-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Crea un nombre completo para un release.
Este será el nombre principal para casi todos los recursos.
Ejemplo: mi-release-user-service
*/}}
{{- define "common-app.fullname" -}}
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
Crea el nombre y la versión del chart.
*/}}
{{- define "common-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Genera las etiquetas estándar que irán en cada recurso.
*/}}
{{- define "common-app.labels" -}}
helm.sh/chart: {{ include "common-app.chart" . }}
{{ include "common-app.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Genera las etiquetas que se usarán en los selectores.
*/}}
{{- define "common-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "common-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}