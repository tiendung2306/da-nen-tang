package com.smartgrocery

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.scheduling.annotation.EnableScheduling

@SpringBootApplication
@EnableScheduling
class SmartGroceryApplication

fun main(args: Array<String>) {
    runApplication<SmartGroceryApplication>(*args)
}