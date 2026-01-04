package com.smartgrocery.service

import com.cloudinary.Cloudinary
import com.cloudinary.utils.ObjectUtils
import com.smartgrocery.exception.ApiException
import com.smartgrocery.exception.ErrorCode
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Service
import org.springframework.util.StringUtils
import org.springframework.web.multipart.MultipartFile
import java.util.*

@Service
class CloudinaryService(
    @Value("\${cloudinary.cloud-name}") private val cloudName: String,
    @Value("\${cloudinary.api-key}") private val apiKey: String,
    @Value("\${cloudinary.api-secret}") private val apiSecret: String,
    @Value("\${cloudinary.folder:smart-grocery}") private val baseFolder: String,
    @Value("\${file.max-size:5242880}") private val maxFileSize: Long
) {
    private val logger = LoggerFactory.getLogger(javaClass)

    private val cloudinary: Cloudinary by lazy {
        Cloudinary(
            ObjectUtils.asMap(
                "cloud_name", cloudName,
                "api_key", apiKey,
                "api_secret", apiSecret,
                "secure", true
            )
        )
    }

    companion object {
        private val ALLOWED_IMAGE_TYPES = setOf(
            "image/jpeg",
            "image/png",
            "image/gif",
            "image/webp"
        )

        private val ALLOWED_EXTENSIONS = setOf(
            "jpg", "jpeg", "png", "gif", "webp"
        )
    }

    /**
     * Upload a file to Cloudinary and return the full URL
     * @param file The file to upload
     * @param subFolder Subfolder within the base folder (e.g., "users", "families")
     * @return Full Cloudinary URL of the uploaded image
     */
    fun uploadFile(file: MultipartFile, subFolder: String = ""): String {
        validateFile(file)

        val folder = if (subFolder.isNotBlank()) {
            "$baseFolder/$subFolder"
        } else {
            baseFolder
        }

        // Generate unique public ID
        val originalFilename = StringUtils.cleanPath(file.originalFilename ?: "file")
        val publicId = "${UUID.randomUUID()}_${originalFilename.substringBeforeLast(".")}"

        try {
            val uploadResult = cloudinary.uploader().upload(
                file.bytes,
                ObjectUtils.asMap(
                    "folder", folder,
                    "public_id", publicId,
                    "resource_type", "image",
                    "overwrite", true
                )
            )

            val secureUrl = uploadResult["secure_url"] as String
            logger.info("File uploaded successfully to Cloudinary: $secureUrl")
            return secureUrl

        } catch (ex: Exception) {
            logger.error("Failed to upload file to Cloudinary", ex)
            throw ApiException(ErrorCode.FILE_UPLOAD_FAILED, "Could not upload file: ${ex.message}")
        }
    }

    /**
     * Delete a file from Cloudinary by its URL
     * @param imageUrl The full Cloudinary URL or public ID
     * @return true if deleted successfully
     */
    fun deleteFile(imageUrl: String): Boolean {
        if (imageUrl.isBlank()) return false

        return try {
            val publicId = extractPublicId(imageUrl)
            if (publicId != null) {
                val result = cloudinary.uploader().destroy(publicId, ObjectUtils.emptyMap())
                val status = result["result"] as? String
                logger.info("File deleted from Cloudinary: $publicId, status: $status")
                status == "ok"
            } else {
                logger.warn("Could not extract public ID from URL: $imageUrl")
                false
            }
        } catch (ex: Exception) {
            logger.error("Failed to delete file from Cloudinary: $imageUrl", ex)
            false
        }
    }

    /**
     * Extract public ID from Cloudinary URL
     * URL format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{folder}/{public_id}.{format}
     */
    private fun extractPublicId(url: String): String? {
        return try {
            // Check if it's a Cloudinary URL
            if (!url.contains("cloudinary.com")) {
                // It might be a public ID directly
                return url
            }

            // Parse the URL to extract public ID
            val regex = Regex("""/upload/(?:v\d+/)?(.+)\.\w+$""")
            val matchResult = regex.find(url)
            matchResult?.groupValues?.get(1)
        } catch (ex: Exception) {
            logger.error("Failed to extract public ID from URL: $url", ex)
            null
        }
    }

    /**
     * Check if Cloudinary is configured properly
     */
    fun isConfigured(): Boolean {
        return cloudName.isNotBlank() && apiKey.isNotBlank() && apiSecret.isNotBlank()
    }

    private fun validateFile(file: MultipartFile) {
        // Check if file is empty
        if (file.isEmpty) {
            throw ApiException(ErrorCode.FILE_UPLOAD_FAILED, "Cannot upload empty file")
        }

        // Check file size
        if (file.size > maxFileSize) {
            throw ApiException(
                ErrorCode.FILE_TOO_LARGE,
                "File size exceeds maximum allowed size of ${maxFileSize / 1024 / 1024}MB"
            )
        }

        // Check content type
        val contentType = file.contentType
        if (contentType == null || contentType !in ALLOWED_IMAGE_TYPES) {
            throw ApiException(
                ErrorCode.INVALID_FILE_TYPE,
                "Only image files are allowed (JPEG, PNG, GIF, WebP)"
            )
        }

        // Check file extension
        val filename = StringUtils.cleanPath(file.originalFilename ?: "")
        val extension = filename.substringAfterLast('.', "").lowercase()
        if (extension !in ALLOWED_EXTENSIONS) {
            throw ApiException(
                ErrorCode.INVALID_FILE_TYPE,
                "Invalid file extension. Allowed: ${ALLOWED_EXTENSIONS.joinToString(", ")}"
            )
        }
    }
}


