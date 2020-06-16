CATALOGS=(
{{- range $p := .addons }}
    stash-{{ $p.name }}
{{- end }}
)
{{ range $p := .addons }}

{{ snakecase $p.name | upper }}_VERSIONS=(
{{- range $p.versions }}
    {{ . }}
{{- end }}
)

{{- end }}
