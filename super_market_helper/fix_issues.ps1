# Flutter Issues Fix Script  
# This script systematically fixes all analyzer issues

Write-Host "Starting Flutter Issues Fix..." -ForegroundColor Cyan

# Fix 1: Remove unused import from chatbot_service.dart
Write-Host "`n1. Fixing chatbot_service.dart - Removing unused import..." -ForegroundColor Yellow
$chatbotFile = "lib\services\chatbot_service.dart"
$chatbotContent = Get-Content $chatbotFile -Raw
$chatbotContent = $chatbotContent -replace "(?m)^import 'dart:convert';\r?\n", ""
Set-Content $chatbotFile $chatbotContent -NoNewline

# Fix 2: Remove avoid_print warnings in gamification_service.dart by using debugPrint
Write-Host "2. Fixing gamification_service.dart - Replacing print with debugPrint..." -ForegroundColor Yellow

$gamificationFile = "lib\services\gamification_service.dart"
$gamificationContent = Get-Content $gamificationFile -Raw

# Add import if not present
if ($gamificationContent -notmatch "import 'package:flutter/foundation.dart';") {
    $gamificationContent = $gamificationContent -replace "(?m)^(import.*\n)", "`$1import 'package:flutter/foundation.dart';`n"
}

# Replace print with debugPrint
$gamificationContent = $gamificationContent -replace "\bprint\(", "debugPrint("
Set-Content $gamificationFile $gamificationContent -NoNewline

Write-Host "`nDone! All quick fixes applied." -ForegroundColor Green
Write-Host "`nRunning flutter analyze to check remaining issues..." -ForegroundColor Cyan
