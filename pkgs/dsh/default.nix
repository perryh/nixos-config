# DeepSeek Harness CLI (dsh) — https://github.com/deepseek-ai/deepseek-harness
# Not in nixpkgs (checked stable 26.05 pin, pinned unstable, and rolling tip),
# so it is packaged here from the published npm artifact (@deepseek-ai/dsh).
#
# src/ is the npm tarball's contents (package.json + prebuilt lib/) plus a
# generated package-lock.json. The lockfile root and package.json have
# devDependencies stripped: one dev dependency
# (@deepseek-ai/dsh-experimental-code-runtime-python) was unpublished from the
# npm registry (404) and npm refuses to resolve the tree for it even with
# --omit=dev. The production closure is exactly what `npm i -g` installs.
#
# To refresh the version:
#   1. re-extract the npm tarball over package.json + lib/ (keeping the
#      devDependencies strip applied)
#   2. regenerate the lockfile in a throwaway project:
#        npm install --package-lock-only --ignore-scripts @deepseek-ai/dsh@<ver>
#      then replace the root (packages[""]) entry with the real package.json
#   3. set npmDepsHash = lib.fakeHash, build, and copy the reported
#      "got: sha256-..." back in
final: prev: {
  dsh = prev.buildNpmPackage {
    pname = "dsh";
    version = "0.1.5-rc.1";

    src = prev.lib.cleanSource ./.;

    # The npm tarball ships the prebuilt CLI (lib/*.js); there is no build step.
    dontNpmBuild = true;

    npmInstallFlags = [ "--omit=dev" ];

    # cordis-plugin-loader enables its internal ESM-loader hook (required by
    # the web profile's HMR plugin) only when process.execArgv contains
    # --expose-internals; the generated wrapper does not pass it, so inject it
    # right after the node binary (first quoted arg of the exec line).
    # --expose-internals is rejected in NODE_OPTIONS, hence the wrapper edit.
    postInstall = ''
      sed -i -E 's|^exec ("[^"]*")|exec \1 --expose-internals|' $out/bin/dsh
      grep -q -- '--expose-internals' $out/bin/dsh
    '';

    npmDepsHash = "sha256-n/OQHKJxL5lKmmgyXvgefLkFW2v5/QlqK6DOv1ozaD8=";

    meta = {
      description = "DeepSeek Harness (dsh) — open-source agent harness; everything is a plugin";
      longDescription = prev.lib.mdDoc ''
        dsh is DeepSeek's open-source agent harness built on an
        everything-is-a-plugin architecture (powered by Cordis).
        `dsh web` starts the browser UI at 127.0.0.1:3080.
      '';
      homepage = "https://github.com/deepseek-ai/deepseek-harness";
      changelog = "https://github.com/deepseek-ai/deepseek-harness/releases";
      license = prev.lib.licenses.mit;
      platforms = prev.lib.platforms.all;
      mainProgram = "dsh";
    };
  };
}
