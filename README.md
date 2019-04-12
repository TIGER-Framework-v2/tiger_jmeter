# tiger_jmeter
TIGER JMeter performance testing image.

## HowTo test this image
docker run -u 1001 --env tests_repo='https://github.com/TIGER-Framework/tiger_jmeter_tests.git' --env test_type=sample tiger_jmeter
