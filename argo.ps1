$apps = @(
    @{ name = "team-a-app1-dev"; path = "apps/team-a/app1/overlays/dev"; namespace = "team-a-dev" },
    @{ name = "team-a-app1-test"; path = "apps/team-a/app1/overlays/test"; namespace = "team-a-test" },
    @{ name = "team-a-app1-prod"; path = "apps/team-a/app1/overlays/prod"; namespace = "team-a-prod" }
)

$repoUrl = "https://github.com/rcorderoayigroup/team-a-MultiEnv.git"
$revision = "main"
$destServer = "https://kubernetes.default.svc"

foreach ($app in $apps) {
    $appName = $app.name
    $path = $app.path
    $namespace = $app.namespace

    Write-Host "🚀 Ejecutando: $appName" -ForegroundColor Cyan

    $cmd = "argocd app create $appName " +
           "--repo $repoUrl " +
           "--revision $revision " +
           "--path $path " +
           "--dest-namespace $namespace " +
           "--dest-server $destServer"

    Invoke-Expression $cmd
}
