# Use PyMySQL as the MySQL driver (pure Python, installs easily on Windows/Linux/macOS).
try:
    import pymysql

    pymysql.install_as_MySQLdb()
except ImportError:  # pragma: no cover - only needed when DB_ENGINE=mysql
    pass
