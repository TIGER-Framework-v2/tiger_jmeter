# tiger_jmeter
TIGER JMeter performance testing image.

## HowTo test this image
`docker run -u 1001 --env tests_repo='https://github.com/TIGER-Framework/tiger_jmeter_tests.git' --env test_type=sample tiger_jmeter`

Please, extend the mentioned command line with additional parameters to enable InfluxDB support, ex.:
`docker run -ti -u 1001 --env tests_repo='https://github.com/TIGER-Framework/tiger_jmeter_tests.git' --env test_type=sample --env current_build_number=1 --env project_id=TIGER --env env_type=dev --env lg_ig=lg_1 --env test_type=sample --env influx_protocol=http --env influx_host=ec00a03fc7 --env influx_port=8087 --env influx_db=jmeter --env influx_username=<username> --env influx_password=<password> tiger_jmeter sh`
