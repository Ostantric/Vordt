deps_config := \
	/home/murat/esp-idf/components/app_trace/Kconfig \
	/home/murat/esp-idf/components/aws_iot/Kconfig \
	/home/murat/esp-idf/components/bt/Kconfig \
	/home/murat/esp-idf/components/driver/Kconfig \
	/home/murat/esp-idf/components/esp32/Kconfig \
	/home/murat/Project_Vordt/Microcontroller/Projects/ESP-IDF-Dev/ESP32_C/components/esp32-snippets-master/Kconfig \
	/home/murat/esp-idf/components/esp_adc_cal/Kconfig \
	/home/murat/esp-idf/components/esp_http_client/Kconfig \
	/home/murat/esp-idf/components/ethernet/Kconfig \
	/home/murat/esp-idf/components/fatfs/Kconfig \
	/home/murat/esp-idf/components/freertos/Kconfig \
	/home/murat/esp-idf/components/heap/Kconfig \
	/home/murat/esp-idf/components/libsodium/Kconfig \
	/home/murat/esp-idf/components/log/Kconfig \
	/home/murat/esp-idf/components/lwip/Kconfig \
	/home/murat/esp-idf/components/mbedtls/Kconfig \
	/home/murat/esp-idf/components/openssl/Kconfig \
	/home/murat/esp-idf/components/pthread/Kconfig \
	/home/murat/esp-idf/components/spi_flash/Kconfig \
	/home/murat/esp-idf/components/spiffs/Kconfig \
	/home/murat/esp-idf/components/tcpip_adapter/Kconfig \
	/home/murat/esp-idf/components/wear_levelling/Kconfig \
	/home/murat/esp-idf/components/bootloader/Kconfig.projbuild \
	/home/murat/esp-idf/components/esptool_py/Kconfig.projbuild \
	/home/murat/esp-idf/components/partition_table/Kconfig.projbuild \
	/home/murat/esp-idf/Kconfig

include/config/auto.conf: \
	$(deps_config)


$(deps_config): ;
