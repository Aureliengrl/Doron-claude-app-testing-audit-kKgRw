$results = @{}
Get-ChildItem -Path 'lib' -Recurse -Filter '*.dart' | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $ms = [regex]::Matches($c, 'Icons\.[a-zA-Z_]+')
    foreach ($m in $ms) {
        $k = $m.Value
        if ($results.ContainsKey($k)) { $results[$k]++ } else { $results[$k] = 1 }
    }
}
$results.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 80 | ForEach-Object { "$($_.Value)  $($_.Key)" }
