package com.smartgrocery.config

import io.swagger.v3.oas.models.Components
import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import io.swagger.v3.oas.models.servers.Server
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

@Configuration
class OpenApiConfig(
    @Value("\${app.base-url:http://localhost:8080}") private val baseUrl: String
) {

    @Bean
    fun customOpenAPI(): OpenAPI {
        val securitySchemeName = "bearerAuth"
        
        val servers = mutableListOf<Server>()
        
        // Add the configured server URL first (will be default in Swagger UI)
        servers.add(Server().url(baseUrl).description("Current Server"))
        
        // Add localhost for development if not already the base URL
        if (!baseUrl.contains("localhost")) {
            servers.add(Server().url("http://localhost:8080").description("Development Server"))
        }
        
        return OpenAPI()
            .info(
                Info()
                    .title("Smart Grocery API")
                    .description("API documentation for Đi chợ tiện lợi (Smart Grocery) application")
                    .version("1.0.0")
                    .contact(
                        Contact()
                            .name("Smart Grocery Team")
                            .email("support@smartgrocery.com")
                    )
                    .license(
                        License()
                            .name("MIT License")
                            .url("https://opensource.org/licenses/MIT")
                    )
            )
            .servers(servers)
            .addSecurityItem(SecurityRequirement().addList(securitySchemeName))
            .components(
                Components()
                    .addSecuritySchemes(
                        securitySchemeName,
                        SecurityScheme()
                            .name(securitySchemeName)
                            .type(SecurityScheme.Type.HTTP)
                            .scheme("bearer")
                            .bearerFormat("JWT")
                    )
            )
    }
}

