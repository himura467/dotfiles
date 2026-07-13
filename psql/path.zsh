if [[ -f "$(dirname "$0")/.psql-version" ]]; then
  psql_version=$(cat "$(dirname "$0")/.psql-version")
  export PATH="/opt/homebrew/opt/postgresql@$psql_version/bin:$PATH"
  export LDFLAGS="-L/opt/homebrew/opt/postgresql@$psql_version/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/postgresql@$psql_version/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/postgresql@$psql_version/lib/pkgconfig"
fi
