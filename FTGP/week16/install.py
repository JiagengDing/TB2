import solcx

print(solcx.get_installable_solc_versions())

solcx.install_solc() # install the latest version

print(solcx.get_installed_solc_versions())