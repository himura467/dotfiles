if [[ -f "$(dirname $0)/.mysql-version" ]]; then
  mysql_version=$(cat "$(dirname $0)/.mysql-version")
  export PATH="/opt/homebrew/opt/mysql@${mysql_version}/bin:$PATH"
  export LDFLAGS="-L/opt/homebrew/opt/mysql@${mysql_version}/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/mysql@${mysql_version}/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql@${mysql_version}/lib/pkgconfig"
fi
