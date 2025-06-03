param (
    [string]$basePath = ".",
    [string[]]$teams = @("team-a", "team-b"),
    [string[]]$apps = @("app1", "app2"),
    [string[]]$environments = @("dev", "test", "prod")
)

function Write-FileContent {
    param (
        [string]$filePath,
        [string]$content
    )
    $content | Out-File -FilePath $filePath -Encoding utf8
    Write-Host "Archivo creado: $filePath"
}

foreach ($team in $teams) {
    $teamPath = Join-Path $basePath $team
    New-Item -Path $teamPath -ItemType Directory -Force | Out-Null

    # Crear project.yaml
    $projectFile = Join-Path $teamPath "project.yaml"
    $destinations = ""
    foreach ($env in $environments) {
        $destinations += "  - namespace: $team-$env`n    server: https://kubernetes.default.svc`n"
    }

    $projectContent = @"
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $team-project
  namespace: argocd
spec:
  description: Proyecto para $team
  sourceRepos:
  - '*'
  destinations:
$destinations  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
"@
    Write-FileContent -filePath $projectFile -content $projectContent

    foreach ($app in $apps) {
        $appPath = Join-Path $teamPath $app
        $baseDir = Join-Path $appPath "base"
        $overlaysDir = Join-Path $appPath "overlays"

        # Crear directorios base y overlays
        New-Item -Path $baseDir -ItemType Directory -Force | Out-Null
        New-Item -Path $overlaysDir -ItemType Directory -Force | Out-Null

        # Crear deployment.yaml base
        $deploymentYaml = @"
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
        image: nginx:latest
        ports:
        - containerPort: 80
"@
        Write-FileContent -filePath (Join-Path $baseDir "deployment.yaml") -content $deploymentYaml

        # Crear kustomization.yaml base
        $kustomBase = @"
resources:
- deployment.yaml
"@
        Write-FileContent -filePath (Join-Path $baseDir "kustomization.yaml") -content $kustomBase

        # Crear overlays para cada entorno
        foreach ($env in $environments) {
            $envPath = Join-Path $overlaysDir $env
            New-Item -Path $envPath -ItemType Directory -Force | Out-Null

            # Crear namespace.yaml
            $namespaceYaml = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $team-$env
"@
            Write-FileContent -filePath (Join-Path $envPath "namespace.yaml") -content $namespaceYaml

            # Crear kustomization.yaml overlay
            $kustomOverlay = @"
resources:
- ../../base
- namespace.yaml
namespace: $team-$env
"@
            Write-FileContent -filePath (Join-Path $envPath "kustomization.yaml") -content $kustomOverlay

            # Aplicar namespace en cluster
            Write-Host "Aplicando namespace: $team-$env"
            kubectl apply -f (Join-Path $envPath "namespace.yaml") | Out-Null
        }
    }
}

Write-Host ""
Write-Host "✅ Estructura completa creada y namespaces aplicados."
Write-Host "👉 Ahora podés crear tus aplicaciones Argo CD apuntando a las carpetas overlays correspondientes."
Write-Host "Ejemplo de creación para app1 dev:"
Write-Host "argocd app create app1-dev --repo https://tu-repo-git.git --path team-a/app1/overlays/dev --dest-namespace team-a-dev --dest-server https://kubernetes.default.svc --project team-a-project"
