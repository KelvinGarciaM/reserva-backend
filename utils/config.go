package utils

import "github.com/spf13/viper"

type Config struct {
	DBDriver          string `mapstructure:"DB_DRIVER"`
	DBSource          string `mapstructure:"DB_SOURCE"`
	ServerURL         string `mapstructure:"SERVER_URL"`
	API               string `mapstructure:"API_VERSION"`
	TokenSymmetricKey string `mapstructure:"TOKEN_SYMMETRIC_KEY"`

	// Usuario quemado
	AdminName     string `mapstructure:"ADMIN_NAME"`
	AdminEmail    string `mapstructure:"ADMIN_EMAIL"`
	AdminPassword string `mapstructure:"ADMIN_PASSWORD"`
	AdminRole     string `mapstructure:"ADMIN_ROLE"`
}

func LoadConfig(path string) (config Config, err error) {
	viper.AddConfigPath(path)
	viper.SetConfigName("app")
	viper.SetConfigType("env")

	viper.AutomaticEnv()

	viper.BindEnv("DB_DRIVER")
	viper.BindEnv("DB_SOURCE")
	viper.BindEnv("SERVER_URL")
	viper.BindEnv("API_VERSION")
	viper.BindEnv("TOKEN_SYMMETRIC_KEY")
	viper.BindEnv("ADMIN_NAME")
	viper.BindEnv("ADMIN_EMAIL")
	viper.BindEnv("ADMIN_PASSWORD")
	viper.BindEnv("ADMIN_ROLE")

	err = viper.ReadInConfig()
	if err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return
		}
	}

	err = viper.Unmarshal(&config)
	return
}
