$apps = @("app1", "app2")
$envs = @("dev", "test", "prod")

foreach ($app in $apps) {
    $basePath = ".\apps\team-a\$app\base"
    $overlayBase = ".\apps\team-a\$app\overlays"

    # Crear carpetas base
    New-Item -ItemType Directory -Force -Path $basePath
    Set-Content "$basePath\kustomization.yaml" @"
resources:
  - deployment.yaml
"@

    # Archivo ficticio base (puede ser reemplazado por Helm chart)
    Set-Content "$basePath\deployment.yaml" @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $app
  template:
    metadata:
      labels:
        app: $app
    spec:
      containers:
      - name: $app
        image: nginx
        ports:
        - containerPort: 80
"@

    # Crear overlays
    foreach ($env in $envs) {
        $envPath = "$overlayBase\$env"
        New-Item -ItemType Directory -Force -Path $envPath

        # Archivo de configuración YAML (puede ser ignorado si no usás Helm)
        Set-Content "$envPath\values-$env.yaml" @"
replicaCount: 1
"@

        Set-Content "$envPath\kustomization.yaml" @"
resources:
  - ../../base

# helmCharts:  # Descomentar si querés usar Helm con Kustomize
#   - name: $app
#     path: ../../base
#     valuesFile: values-$env.yaml
"@
    }
}
