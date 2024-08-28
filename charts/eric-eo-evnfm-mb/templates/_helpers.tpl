{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "eric-eo-evnfm-mb.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "eric-eo-evnfm-mb.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- template "eric-eo-evnfm-mb.name" . -}}
{{- end -}}
{{- end -}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-eo-evnfm-mb.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-eo-evnfm-mb.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper RabbitMQ plugin list
*/}}
{{- define "eric-eo-evnfm-mb.plugins" -}}
{{- $plugins := .Values.rabbitmq.plugins | replace " " ", " -}}
{{- if .Values.rabbitmq.extraPlugins -}}
{{- $extraPlugins := .Values.rabbitmq.extraPlugins | replace " " ", " -}}
{{- printf "[%s, %s]." $plugins $extraPlugins | indent 4 -}}
{{- else -}}
{{- printf "[%s]." $plugins | indent 4 -}}
{{- end -}}
{{- end -}}

{{/*
Get the password secret.
*/}}
{{- define "eric-eo-evnfm-mb.rmqSecretName" -}}
    {{- if .Values.credentials.kubernetesSecretName -}}
        {{- printf "%s" .Values.credentials.kubernetesSecretName -}}
    {{- else -}}
        {{ required "A valid Values.credentials.kubernetesSecretName is required!" .Values.credentials.kubernetesSecretName }}
    {{- end -}}
{{- end -}}

{{/*
Get the erlang secret.
*/}}
{{- define "eric-eo-evnfm-mb.secretErlangName" -}}
    {{- if .Values.rabbitmq.existingErlangSecret -}}
        {{- printf "%s" .Values.rabbitmq.existingErlangSecret -}}
    {{- else -}}
        {{- printf "%s" (include "eric-eo-evnfm-mb.name" .) -}}
    {{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "eric-eo-evnfm-mb.imagePullSecrets" -}}
{{- if .Values.imageCredentials.registry.pullSecret -}}
imagePullSecrets:
  - name: {{ .Values.imageCredentials.registry.pullSecret }}
{{- else if .Values.global.registry.pullSecret -}}
imagePullSecrets:
  - name: {{ .Values.global.registry.pullSecret }}
{{- end -}}
{{- end -}}


{{/*
Return  the proper Storage Class
*/}}
{{- define "eric-eo-evnfm-mb.storageClass" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 does not support it, so we need to implement this if-else logic.
*/}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- if (eq "-" .Values.global.storageClass) -}}
            {{- printf "storageClassName: \"\"" -}}
        {{- else }}
            {{- printf "storageClassName: %s" .Values.global.storageClass -}}
        {{- end -}}
    {{- else -}}
        {{- if .Values.persistence.persistentVolumeClaim.storageClass -}}
              {{- if (eq "-" .Values.persistence.persistentVolumeClaim.storageClass) -}}
                  {{- printf "storageClassName: \"\"" -}}
              {{- else }}
                  {{- printf "storageClassName: %s" .Values.persistence.persistentVolumeClaim.storageClass -}}
              {{- end -}}
        {{- end -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.persistence.persistentVolumeClaim.storageClass -}}
        {{- if (eq "-" .Values.persistence.persistentVolumeClaim.storageClass) -}}
            {{- printf "storageClassName: \"\"" -}}
        {{- else }}
            {{- printf "storageClassName: %s" .Values.persistence.persistentVolumeClaim.storageClass -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create main image registry url
*/}}
{{- define "eric-eo-evnfm-mb.mainImagePath" -}}
    {{- include "eric-eo-evnfm-library-chart.mainImagePath" (dict "ctx" . "svcRegistryName" "evnfmMB") -}}
{{- end -}}

{{/*
Create volume permissions image registry url
*/}}
{{- define "eric-eo-evnfm-mb.volumePermissionsImagePath" -}}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.volumePermissions.registry -}}
    {{- $repoPath := $productInfo.images.volumePermissions.repoPath -}}
    {{- $name := $productInfo.images.volumePermissions.name -}}
    {{- $tag := $productInfo.images.volumePermissions.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.volumePermissions -}}
            {{- if .Values.imageCredentials.volumePermissions.registry -}}
                {{- if .Values.imageCredentials.volumePermissions.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.volumePermissions.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.volumePermissions.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.volumePermissions.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-eo-evnfm-mb.pullSecrets" -}}
  {{- include "eric-eo-evnfm-library-chart.pullSecrets" . -}}
{{- end -}}


{{/*
Create Ericsson Product Info
*/}}
{{- define "eric-eo-evnfm-mb.helm-annotations" -}}
{{- include "eric-eo-evnfm-library-chart.helm-annotations" . -}}
{{- end -}}


{{/*
Create Ericsson product app.kubernetes.io info
*/}}
{{- define "eric-eo-evnfm-mb.kubernetes-io-info" -}}
{{- include "eric-eo-evnfm-library-chart.kubernetes-io-info" . -}}
{{- end -}}

{{/*
Create pullPolicy for init container
*/}}
{{- define "eric-eo-evnfm-mb.sles.imagePullPolicy" -}}
  {{- include "eric-eo-evnfm-library-chart.imagePullPolicy" (dict "ctx" . "svcRegistryName" "sles") -}}
{{- end -}}


{{/*
Create pullPolicy for eric-eo-evnfm-mb container
*/}}
{{- define "eric-eo-evnfm-mb.imagePullPolicy" -}}
  {{- include "eric-eo-evnfm-library-chart.imagePullPolicy" (dict "ctx" . "svcRegistryName" "evnfmMB") -}}
{{- end -}}


{{/*
The name of the cluster role used during openshift deployments.
This helper is provided to allow use of the new global.security.privilegedPolicyClusterRoleName if set, otherwise
use the previous naming convention of <name>-allowed-use-privileged-policy for backwards compatibility.
*/}}
{{- define "eric-eo-evnfm-mb.privileged.cluster.role.name" -}}
{{- include "eric-eo-evnfm-library-chart.privileged.cluster.role.name" ( dict "ctx" . "svcName" (include "eric-eo-evnfm-mb.name" .) ) -}}
{{- end -}}

{{- define "eric-eo-evnfm-mb.nodeSelector" -}}
  {{- include "eric-eo-evnfm-library-chart.nodeSelector" . -}}
{{- end -}}

{{/*
Kubernetes labels
*/}}
{{- define "eric-eo-evnfm-mb.kubernetes-labels" -}}
app.kubernetes.io/name: {{ include "eric-eo-evnfm-mb.name" . }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ include "eric-eo-evnfm-mb.version" . }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "eric-eo-evnfm-mb.labels" -}}
  {{- $kubernetesLabels := include "eric-eo-evnfm-mb.kubernetes-labels" . | fromYaml -}}
  {{- $globalLabels := (.Values.global).labels -}}
  {{- $serviceLabels := .Values.labels -}}
  {{- include "eric-eo-evnfm-library-chart.mergeLabels" (dict "location" .Template.Name "sources" (list $kubernetesLabels $globalLabels $serviceLabels)) }}
{{- end -}}

{{/*
Merged labels for extended defaults
*/}}
{{- define "eric-eo-evnfm-mb.labels.extended-defaults" -}}
  {{- $extendedLabels := dict -}}
  {{- $_ := set $extendedLabels "app" (include "eric-eo-evnfm-mb.name" .) -}}
  {{- $_ := set $extendedLabels "chart" (include "eric-eo-evnfm-mb.chart" .) -}}
  {{- $_ := set $extendedLabels "release" (.Release.Name) -}}
  {{- $_ := set $extendedLabels "heritage" (.Release.Service) -}}
  {{- $commonLabels := include "eric-eo-evnfm-mb.labels" . | fromYaml -}}
  {{- include "eric-eo-evnfm-library-chart.mergeLabels" (dict "location" .Template.Name "sources" (list $commonLabels $extendedLabels)) | trim }}
{{- end -}}

{{/*
Create Ericsson product specific annotations
*/}}
{{- define "eric-eo-evnfm-mb.helm-annotations_product_name" -}}
{{- include "eric-eo-evnfm-library-chart.helm-annotations_product_name" . -}}
{{- end -}}
{{- define "eric-eo-evnfm-mb.helm-annotations_product_number" -}}
{{- include "eric-eo-evnfm-library-chart.helm-annotations_product_number" . -}}
{{- end -}}
{{- define "eric-eo-evnfm-mb.helm-annotations_product_revision" -}}
{{- include "eric-eo-evnfm-library-chart.helm-annotations_product_revision" . -}}
{{- end -}}

{{/*
Create a dict of annotations for the product information (DR-D1121-064, DR-D1121-067).
*/}}
{{- define "eric-eo-evnfm-mb.product-info" }}
ericsson.com/product-name: {{ template "eric-eo-evnfm-mb.helm-annotations_product_name" . }}
ericsson.com/product-number: {{ template "eric-eo-evnfm-mb.helm-annotations_product_number" . }}
ericsson.com/product-revision: {{ template "eric-eo-evnfm-mb.helm-annotations_product_revision" . }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "eric-eo-evnfm-mb.annotations" -}}
  {{- $productInfo := include "eric-eo-evnfm-mb.product-info" . | fromYaml -}}
  {{- $globalAnn := (.Values.global).annotations -}}
  {{- $serviceAnn := .Values.annotations -}}
  {{- include "eric-eo-evnfm-library-chart.mergeAnnotations" (dict "location" .Template.Name "sources" (list $productInfo $globalAnn $serviceAnn)) | trim }}
{{- end -}}

{{/*
Define probes
*/}}
{{- define "eric-eo-evnfm-mb.probes" -}}
{{- $default := .Values.probes -}}
{{- if .Values.probing }}
  {{- if .Values.probing.liveness }}
    {{- if .Values.probing.liveness.messagebus }}
      {{- $default := mergeOverwrite $default.messagebus.livenessProbe .Values.probing.liveness.messagebus  -}}
    {{- end }}
  {{- end }}
  {{- if .Values.probing.readiness }}
    {{- if .Values.probing.readiness.messagebus }}
      {{- $default := mergeOverwrite $default.messagebus.readinessProbe .Values.probing.readiness.messagebus  -}}
    {{- end }}
  {{- end }}
{{- end }}
{{- $default | toJson -}}
{{- end -}}

{{- define "eric-eo-evnfm-mb.podPriority" -}}
{{- include "eric-eo-evnfm-library-chart.podPriority" ( dict "ctx" . "svcName" "messagebus" ) -}}
{{- end -}}

{{/*
To support Dual stack.
*/}}
{{- define "eric-eo-evnfm-mb.internalIPFamily" -}}
{{- include "eric-eo-evnfm-library-chart.internalIPFamily" . -}}
{{- end -}}

{{- define "eric-eo-evnfm-mb.tolerations.messagebus" -}}
{{- if .Values.tolerations.messagebus -}}
  {{- if ne (len .Values.tolerations.messagebus) 0 -}}
    {{- toYaml .Values.tolerations.messagebus -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "eric-eo-evnfm-mb.fsGroup.coordinated" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.fsGroup -}}
            {{- if .Values.global.fsGroup.manual -}}
                {{ .Values.global.fsGroup.manual }}
            {{- else -}}
                {{- if eq .Values.global.fsGroup.namespace true -}}
                     # The 'default' defined in the Security Policy will be used.
                {{- else -}}
                    10000
                {{- end -}}
            {{- end -}}
        {{- else -}}
            10000
        {{- end -}}
    {{- else -}}
        10000
    {{- end -}}
{{- end -}}

{{/*
DR-D1123-124
Evaluating the Security Policy Cluster Role Name
*/}}
{{- define "eric-eo-evnfm-mb.securityPolicy.reference" -}}
{{- include "eric-eo-evnfm-library-chart.securityPolicy.reference" . -}}
{{- end -}}