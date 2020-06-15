CATALOGS=(
{{- range $p := .projects }}
    stash-{{ $p.name }}
{{- end }}
)
{{ range $p := .projects }}

{{ snakecase $p.name | upper }}_VERSIONS=(
{{- range $p.versions }}
    {{ . }}
{{- end }}
)

{{- end }}
