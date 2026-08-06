@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM  Forks @types/pako -> @zklogic/types-pako
REM  1. Copies the currently installed @types/pako sources
REM  2. Rewrites package.json under the new scope
REM  3. Inits a git repo for the fork (push to GitHub yourself)
REM  4. Publishes to the public npmjs registry
REM
REM  Run this from the mazadat-frontend project root.
REM  Requires: git, npm, and `npm login` already done against npmjs
REM  (npm login, no registry flag needed) with access to the
REM  @zklogic org/scope on npmjs.com.
REM ============================================================

set SOURCE_DIR=%~dp0..\node_modules\@types\pako
set FORK_DIR=C:\elm\github\types-pako
set NEW_SCOPE=@zklogic
set NEW_NAME=%NEW_SCOPE%/types-pako
set NEW_VERSION=2.0.4-zklogic.1
set GITHUB_REPO_URL=https://github.com/zklogic/types-pako.git

set NEXUS_REGISTRY=https://registry.npmjs.org/

if not exist "%SOURCE_DIR%" (
  echo [ERROR] %SOURCE_DIR% not found. Run "npm install" in this project first.
  exit /b 1
)

echo === Step 1: Preparing fork directory at %FORK_DIR% ===
if exist "%FORK_DIR%" (
  echo Removing existing folder...
  rmdir /s /q "%FORK_DIR%"
)
mkdir "%FORK_DIR%"

echo === Step 2: Copying type definition files ===
copy "%SOURCE_DIR%\index.d.ts" "%FORK_DIR%\index.d.ts" >nul
copy "%SOURCE_DIR%\LICENSE" "%FORK_DIR%\LICENSE" >nul

echo === Step 3: Writing README.md ===
(
  echo # %NEW_NAME%
  echo.
  echo TypeScript definitions for [pako]^(https://github.com/nodeca/pako^),
  echo forked from `@types/pako` and maintained by zklogic.
  echo.
  echo `@types/pako` upstream is a deprecated stub referencing pako's own
  echo bundled types, but the resolved `pako` version in this project ^(2.1.0^)
  echo does not ship its own types, so this fork keeps a working copy.
  echo.
  echo ## Installation
  echo ```
  echo npm install --save-dev %NEW_NAME%
  echo ```
  echo.
  echo ## Original source
  echo Files were originally exported from
  echo https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/pako.
) > "%FORK_DIR%\README.md"

echo === Step 4: Writing package.json ===
(
  echo {
  echo   "name": "%NEW_NAME%",
  echo   "version": "%NEW_VERSION%",
  echo   "description": "TypeScript definitions for pako ^(zklogic-maintained fork of @types/pako^)",
  echo   "main": "",
  echo   "types": "index.d.ts",
  echo   "license": "MIT",
  echo   "repository": {
  echo     "type": "git",
  echo     "url": "%GITHUB_REPO_URL%"
  echo   },
  echo   "publishConfig": {
  echo     "access": "public",
  echo     "registry": "%NEXUS_REGISTRY%"
  echo   }
  echo }
) > "%FORK_DIR%\package.json"

echo === Step 5: git init ===
pushd "%FORK_DIR%"
git init -q
git branch -M main
git add .
git commit -q -m "Fork @types/pako as %NEW_NAME%"
echo.
echo Fork prepared at: %FORK_DIR%
echo Next manual steps:
echo   1. Create the repo at %GITHUB_REPO_URL% on GitHub (if it doesn't exist yet)
echo   2. git remote add origin %GITHUB_REPO_URL%
echo   3. git push -u origin main
echo.

echo === Step 6: Publish to npmjs ===
set /p DOPUBLISH="Publish %NEW_NAME%@%NEW_VERSION% to %NEXUS_REGISTRY% now? (y/N): "
if /i "%DOPUBLISH%"=="y" (
  npm publish --access public --registry=%NEXUS_REGISTRY%
  if errorlevel 1 (
    echo [ERROR] Publish failed. Make sure you're logged in and the @zklogic
    echo         org/scope exists on npmjs.com with your account as a member:
    echo   npm login
    echo   npm whoami
  ) else (
    echo Published %NEW_NAME%@%NEW_VERSION% successfully.
    echo View at: https://www.npmjs.com/package/%NEW_NAME%
  )
) else (
  echo Skipped publish. To push to GitHub and publish later, run from %FORK_DIR%:
  echo   git remote add origin %GITHUB_REPO_URL%
  echo   git push -u origin main
  echo   npm publish --access public --registry=%NEXUS_REGISTRY%
)

popd
endlocal
