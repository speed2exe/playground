from clickhouse_driver import Client

client = Client('localhost', compression=True)
print(client.execute('show databases'))
