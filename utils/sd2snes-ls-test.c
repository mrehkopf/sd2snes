#define _POSIX_C_SOURCE 200809L

/*
 * Standalone exerciser for the sd2snes direct USB LS command.
 *
 * Build:
 *   cc -std=c11 -Wall -Wextra -Wpedantic sd2snes-ls-test.c \
 *      $(pkg-config --cflags --libs libusb-1.0) -o sd2snes-ls-test
 */

#include <errno.h>
#include <getopt.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <libusb.h>

#define SD2SNES_VID 0x1209
#define SD2SNES_PID 0x5a22

#define CDC_CONTROL_INTERFACE 0
#define CDC_DATA_INTERFACE 1
#define CDC_SET_CONTROL_LINE_STATE 0x22
#define CDC_DTR 0x0001

#define USB_EP_OUT 0x02
#define USB_EP_IN 0x82

#define USB_BLOCK_SIZE 512
#define USB_OPCODE_LS 0x04
#define USB_OPCODE_INFO 0x0b
#define USB_OPCODE_RESPONSE 0x0f
#define USB_SPACE_FILE 0x00
#define USB_FLAG_64B_DATA 0x80

#define LS_FILESIZE 0x01
#define LS_FILEDATE 0x02
#define LS_FILETIME 0x04
#define LS_ATTRIBUTE 0x08
#define LS_ALL_METADATA 0x0f

#define MAX_TEST_FLAGS 16
#define MAX_LISTING_BLOCKS 65536U

struct options {
    const char *path;
    unsigned timeout_ms;
    unsigned block_mode;
    bool summary;
    bool all_combinations;
    uint8_t flags[MAX_TEST_FLAGS];
    size_t flag_count;
};

struct device_connection {
    libusb_device_handle *handle;
    bool control_claimed;
    bool data_claimed;
};

struct listing_result {
    unsigned blocks;
    unsigned entries;
    bool complete;
    bool needs_resync;
};

static void usage(FILE *stream, const char *program)
{
    fprintf(stream,
            "Usage: %s [options]\n"
            "\n"
            "Find the USB device 1209:5a22 and exercise its LS opcode.\n"
            "Without --flags, tests metadata masks 0, 1, 2, 4, 8, and 15.\n"
            "\n"
            "Options:\n"
            "  -p, --path PATH          directory to list (default: /)\n"
            "  -f, --flags MASK         metadata mask 0..15; may be repeated\n"
            "  -a, --all-combinations   test all 16 metadata masks\n"
            "  -B, --block-size SIZE    512 (default), 64, or both\n"
            "  -t, --timeout MS         per-transfer timeout (default: 3000)\n"
            "  -s, --summary            suppress individual directory entries\n"
            "  -h, --help               show this help\n"
            "\n"
            "Metadata mask: 1=size, 2=FAT date, 4=FAT time, 8=attributes.\n"
            "Caution: a record longer than 64 bytes cannot be returned with\n"
            "--block-size 64; the tool detects this and resets the connection.\n",
            program);
}

static bool parse_unsigned(const char *text, unsigned max, unsigned *value)
{
    char *end = NULL;
    unsigned long parsed;

    errno = 0;
    parsed = strtoul(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0' || parsed > max) {
        return false;
    }
    *value = (unsigned)parsed;
    return true;
}

static int parse_options(int argc, char **argv, struct options *options)
{
    static const struct option long_options[] = {
        { "path",             required_argument, NULL, 'p' },
        { "flags",            required_argument, NULL, 'f' },
        { "all-combinations", no_argument,       NULL, 'a' },
        { "block-size",       required_argument, NULL, 'B' },
        { "timeout",          required_argument, NULL, 't' },
        { "summary",          no_argument,       NULL, 's' },
        { "help",             no_argument,       NULL, 'h' },
        { NULL, no_argument, NULL, 0 },
    };
    int option;

    memset(options, 0, sizeof(*options));
    options->path = "/";
    options->timeout_ms = 3000;
    options->block_mode = 512;

    opterr = 0;
    optind = 1;
    while ((option = getopt_long(argc, argv, ":p:f:aB:t:sh", long_options, NULL)) != -1) {
        switch (option) {
        case 'p':
            options->path = optarg;
            break;

        case 'f': {
            unsigned parsed;
            if (!parse_unsigned(optarg, LS_ALL_METADATA, &parsed)) {
                fprintf(stderr, "invalid LS metadata mask: %s\n", optarg);
                return -1;
            }
            if (options->flag_count == MAX_TEST_FLAGS) {
                fprintf(stderr, "too many --flags arguments\n");
                return -1;
            }
            options->flags[options->flag_count++] = (uint8_t)parsed;
            break;
        }

        case 'a':
            options->all_combinations = true;
            break;

        case 'B':
            if (strcmp(optarg, "64") == 0) {
                options->block_mode = 64;
            } else if (strcmp(optarg, "512") == 0) {
                options->block_mode = 512;
            } else if (strcmp(optarg, "both") == 0) {
                options->block_mode = 576;
            } else {
                fprintf(stderr, "invalid block size: %s\n", optarg);
                return -1;
            }
            break;

        case 't':
            if (!parse_unsigned(optarg, 600000, &options->timeout_ms) ||
                options->timeout_ms == 0) {
                fprintf(stderr, "invalid timeout: %s\n", optarg);
                return -1;
            }
            break;

        case 's':
            options->summary = true;
            break;

        case 'h':
            usage(stdout, argv[0]);
            return 1;

        case ':':
            fprintf(stderr, "option requires an argument: %s\n",
                    argv[optind - 1]);
            return -1;

        case '?':
        default:
            fprintf(stderr, "unknown option: %s\n", argv[optind - 1]);
            return -1;
        }
    }

    if (optind != argc) {
        fprintf(stderr, "unexpected positional argument: %s\n", argv[optind]);
        return -1;
    }

    if (strlen(options->path) > 255) {
        fprintf(stderr, "path is longer than the protocol's 255-byte limit\n");
        return -1;
    }
    if (options->all_combinations && options->flag_count != 0) {
        fprintf(stderr, "--all-combinations cannot be combined with --flags\n");
        return -1;
    }
    return 0;
}

static void sleep_ms(unsigned milliseconds)
{
    struct timespec delay;

    delay.tv_sec = (time_t)(milliseconds / 1000);
    delay.tv_nsec = (long)(milliseconds % 1000) * 1000000L;
    while (nanosleep(&delay, &delay) != 0 && errno == EINTR) {
    }
}

static const char *usb_error(int error)
{
    return libusb_strerror((enum libusb_error)error);
}

static int set_dtr(libusb_device_handle *handle, bool asserted,
                   unsigned timeout_ms)
{
    int result = libusb_control_transfer(
        handle,
        LIBUSB_ENDPOINT_OUT | LIBUSB_REQUEST_TYPE_CLASS |
            LIBUSB_RECIPIENT_INTERFACE,
        CDC_SET_CONTROL_LINE_STATE, asserted ? CDC_DTR : 0,
        CDC_CONTROL_INTERFACE, NULL, 0, timeout_ms);

    if (result < 0) {
        fprintf(stderr, "could not %s DTR: %s\n",
                asserted ? "assert" : "deassert", usb_error(result));
        return -1;
    }
    return 0;
}

static void drain_input(libusb_device_handle *handle)
{
    unsigned char discard[USB_BLOCK_SIZE];
    unsigned drained = 0;

    for (;;) {
        int transferred = 0;
        int result = libusb_bulk_transfer(handle, USB_EP_IN, discard,
                                          sizeof(discard), &transferred, 20);
        if (transferred > 0) {
            drained += (unsigned)transferred;
        }
        if (result == LIBUSB_ERROR_TIMEOUT || (result == 0 && transferred == 0)) {
            break;
        }
        if (result != 0) {
            fprintf(stderr, "warning: could not drain USB input: %s\n",
                    usb_error(result));
            break;
        }
    }
    if (drained != 0) {
        fprintf(stderr, "warning: discarded %u stale input bytes\n", drained);
    }
}

static int reset_connection(struct device_connection *connection,
                            unsigned timeout_ms)
{
    if (set_dtr(connection->handle, false, timeout_ms) != 0) {
        return -1;
    }
    sleep_ms(30);
    drain_input(connection->handle);
    if (set_dtr(connection->handle, true, timeout_ms) != 0) {
        return -1;
    }
    sleep_ms(30);
    return 0;
}

static void print_usb_string(libusb_device_handle *handle, uint8_t index,
                             const char *label)
{
    unsigned char text[256];
    int length;

    if (index == 0) {
        return;
    }
    length = libusb_get_string_descriptor_ascii(handle, index, text,
                                                 sizeof(text) - 1);
    if (length > 0) {
        text[length] = '\0';
        printf("  %s: %s\n", label, text);
    }
}

static int open_device(libusb_context *context,
                       struct device_connection *connection)
{
    libusb_device **devices = NULL;
    ssize_t count;
    ssize_t i;
    int last_open_error = LIBUSB_ERROR_NO_DEVICE;

    memset(connection, 0, sizeof(*connection));
    count = libusb_get_device_list(context, &devices);
    if (count < 0) {
        fprintf(stderr, "could not enumerate USB devices: %s\n",
                usb_error((int)count));
        return -1;
    }

    for (i = 0; i < count; ++i) {
        struct libusb_device_descriptor descriptor;
        libusb_device *device = devices[i];
        int result = libusb_get_device_descriptor(device, &descriptor);

        if (result != 0 || descriptor.idVendor != SD2SNES_VID ||
            descriptor.idProduct != SD2SNES_PID) {
            continue;
        }
        result = libusb_open(device, &connection->handle);
        if (result != 0) {
            last_open_error = result;
            continue;
        }

        printf("Found %04x:%04x at bus %u address %u\n", descriptor.idVendor,
               descriptor.idProduct, libusb_get_bus_number(device),
               libusb_get_device_address(device));
        print_usb_string(connection->handle, descriptor.iManufacturer,
                         "manufacturer");
        print_usb_string(connection->handle, descriptor.iProduct, "product");
        print_usb_string(connection->handle, descriptor.iSerialNumber, "serial");
        break;
    }
    libusb_free_device_list(devices, 1);

    if (connection->handle == NULL) {
        if (last_open_error == LIBUSB_ERROR_NO_DEVICE) {
            fprintf(stderr, "no sd2snes USB device (%04x:%04x) found\n",
                    SD2SNES_VID, SD2SNES_PID);
        } else {
            fprintf(stderr, "sd2snes found but could not be opened: %s\n",
                    usb_error(last_open_error));
            fprintf(stderr, "check device permissions and whether another program has it open\n");
        }
        return -1;
    }

    {
        int result = libusb_set_auto_detach_kernel_driver(connection->handle, 1);
        if (result != 0 && result != LIBUSB_ERROR_NOT_SUPPORTED) {
            fprintf(stderr, "could not enable automatic kernel-driver detach: %s\n",
                    usb_error(result));
            return -1;
        }
    }
    {
        int result = libusb_claim_interface(connection->handle,
                                            CDC_CONTROL_INTERFACE);
        if (result != 0) {
            fprintf(stderr, "could not claim CDC control interface: %s\n",
                    usb_error(result));
            return -1;
        }
    }
    connection->control_claimed = true;
    {
        int result = libusb_claim_interface(connection->handle, CDC_DATA_INTERFACE);
        if (result != 0) {
            fprintf(stderr, "could not claim CDC data interface: %s\n",
                    usb_error(result));
            return -1;
        }
    }
    connection->data_claimed = true;
    return 0;
}

static void close_device(struct device_connection *connection,
                         unsigned timeout_ms)
{
    if (connection->handle == NULL) {
        return;
    }
    if (connection->control_claimed) {
        (void)set_dtr(connection->handle, false, timeout_ms);
    }
    if (connection->data_claimed) {
        (void)libusb_release_interface(connection->handle, CDC_DATA_INTERFACE);
    }
    if (connection->control_claimed) {
        (void)libusb_release_interface(connection->handle,
                                       CDC_CONTROL_INTERFACE);
    }
    libusb_close(connection->handle);
    connection->handle = NULL;
}

static int bulk_write_all(libusb_device_handle *handle,
                          const unsigned char *data, size_t size,
                          unsigned timeout_ms)
{
    size_t offset = 0;

    while (offset < size) {
        int transferred = 0;
        int result = libusb_bulk_transfer(handle, USB_EP_OUT,
                                          (unsigned char *)data + offset,
                                          (int)(size - offset), &transferred,
                                          timeout_ms);
        if (transferred > 0) {
            offset += (size_t)transferred;
        }
        if (result == LIBUSB_ERROR_TIMEOUT && transferred > 0) {
            continue;
        }
        if (result != 0) {
            fprintf(stderr, "USB write failed after %zu/%zu bytes: %s\n",
                    offset, size, usb_error(result));
            return -1;
        }
        if (transferred == 0) {
            fprintf(stderr, "USB write made no progress\n");
            return -1;
        }
    }
    return 0;
}

static int bulk_read_exact(libusb_device_handle *handle, unsigned char *data,
                           size_t size, unsigned timeout_ms)
{
    size_t offset = 0;
    unsigned zero_length_packets = 0;

    while (offset < size) {
        int transferred = 0;
        int result = libusb_bulk_transfer(handle, USB_EP_IN, data + offset,
                                          (int)(size - offset), &transferred,
                                          timeout_ms);
        if (transferred > 0) {
            offset += (size_t)transferred;
            zero_length_packets = 0;
        }
        if (result == LIBUSB_ERROR_TIMEOUT && transferred > 0) {
            continue;
        }
        if (result != 0) {
            fprintf(stderr, "USB read failed after %zu/%zu bytes: %s\n",
                    offset, size, usb_error(result));
            return -1;
        }
        if (transferred == 0 && ++zero_length_packets > 4) {
            fprintf(stderr, "USB read received too many zero-length packets\n");
            return -1;
        }
    }
    return 0;
}

static uint16_t read_le16(const unsigned char *data)
{
    return (uint16_t)data[0] | (uint16_t)((uint16_t)data[1] << 8);
}

static uint32_t read_le32(const unsigned char *data)
{
    return (uint32_t)data[0] | ((uint32_t)data[1] << 8) |
           ((uint32_t)data[2] << 16) | ((uint32_t)data[3] << 24);
}

static uint32_t read_be32(const unsigned char *data)
{
    return ((uint32_t)data[0] << 24) | ((uint32_t)data[1] << 16) |
           ((uint32_t)data[2] << 8) | (uint32_t)data[3];
}

static void print_name(const unsigned char *name, size_t length)
{
    size_t i;

    putchar('"');
    for (i = 0; i < length; ++i) {
        unsigned char c = name[i];
        if (c == '\\' || c == '"') {
            printf("\\%c", c);
        } else if (c >= 0x20 && c <= 0x7e) {
            putchar(c);
        } else {
            printf("\\x%02x", c);
        }
    }
    putchar('"');
}

static void print_fat_date(uint16_t date)
{
    unsigned year = 1980U + ((date >> 9) & 0x7fU);
    unsigned month = (date >> 5) & 0x0fU;
    unsigned day = date & 0x1fU;

    printf("%04u-%02u-%02u", year, month, day);
}

static void print_fat_time(uint16_t time)
{
    unsigned hour = (time >> 11) & 0x1fU;
    unsigned minute = (time >> 5) & 0x3fU;
    unsigned second = (time & 0x1fU) * 2U;

    printf("%02u:%02u:%02u", hour, minute, second);
}

static int validate_response(const unsigned char *response, uint8_t *error)
{
    if (memcmp(response, "USBA", 4) != 0) {
        fprintf(stderr, "malformed response: bad magic\n");
        return -1;
    }
    if (response[4] != USB_OPCODE_RESPONSE) {
        fprintf(stderr, "malformed response: opcode is 0x%02x, expected 0x%02x\n",
                response[4], USB_OPCODE_RESPONSE);
        return -1;
    }
    *error = response[5];
    return 0;
}

static int query_info(struct device_connection *connection,
                      unsigned timeout_ms)
{
    unsigned char request[USB_BLOCK_SIZE] = {0};
    unsigned char response[USB_BLOCK_SIZE];
    uint8_t error;

    memcpy(request, "USBA", 4);
    request[4] = USB_OPCODE_INFO;
    if (bulk_write_all(connection->handle, request, sizeof(request), timeout_ms) != 0 ||
        bulk_read_exact(connection->handle, response, sizeof(response), timeout_ms) != 0 ||
        validate_response(response, &error) != 0) {
        return -1;
    }
    if (error != 0) {
        fprintf(stderr, "INFO returned device error %u\n", error);
        return -1;
    }

    response[323] = '\0';
    response[387] = '\0';
    printf("Firmware: %s (%s)\n", response + 260, response + 324);
    return 0;
}

static int parse_listing_block(const unsigned char *block, size_t block_size,
                               uint8_t metadata_flags, bool summary,
                               struct listing_result *result)
{
    size_t offset = 0;

    while (offset < block_size) {
        uint8_t kind = block[offset++];
        uint32_t size = 0;
        uint16_t date = 0;
        uint16_t time = 0;
        uint8_t attributes = 0;
        const unsigned char *terminator;
        size_t name_length;

        if (kind == 0xff) {
            result->complete = true;
            return 1;
        }
        if (kind == 0x02) {
            if (offset == 1) {
                fprintf(stderr,
                        "record cannot fit in an empty %zu-byte block; listing would loop forever\n",
                        block_size);
                result->needs_resync = true;
                return -1;
            }
            return 0;
        }
        if (kind != 0x00 && kind != 0x01) {
            fprintf(stderr, "malformed LS record at block offset %zu: type 0x%02x\n",
                    offset - 1, kind);
            result->needs_resync = true;
            return -1;
        }

#define REQUIRE_BYTES(count)                                                   \
        do {                                                                   \
            if ((count) > block_size - offset) {                               \
                fprintf(stderr, "metadata overruns LS data block\n");          \
                result->needs_resync = true;                                   \
                return -1;                                                     \
            }                                                                  \
        } while (0)

        if ((metadata_flags & LS_FILESIZE) != 0) {
            REQUIRE_BYTES(4);
            size = read_le32(block + offset);
            offset += 4;
        }
        if ((metadata_flags & LS_FILEDATE) != 0) {
            REQUIRE_BYTES(2);
            date = read_le16(block + offset);
            offset += 2;
        }
        if ((metadata_flags & LS_FILETIME) != 0) {
            REQUIRE_BYTES(2);
            time = read_le16(block + offset);
            offset += 2;
        }
        if ((metadata_flags & LS_ATTRIBUTE) != 0) {
            REQUIRE_BYTES(1);
            attributes = block[offset++];
        }
#undef REQUIRE_BYTES

        terminator = memchr(block + offset, '\0', block_size - offset);
        if (terminator == NULL) {
            fprintf(stderr, "filename is not NUL-terminated within its LS data block\n");
            result->needs_resync = true;
            return -1;
        }
        name_length = (size_t)(terminator - (block + offset));
        ++result->entries;

        if (!summary) {
            printf("  %-4s ", kind == 0x00 ? "DIR" : "FILE");
            print_name(block + offset, name_length);
            if ((metadata_flags & LS_FILESIZE) != 0) {
                printf(" size=%" PRIu32, size);
            }
            if ((metadata_flags & LS_FILEDATE) != 0) {
                printf(" date=");
                print_fat_date(date);
                printf("[0x%04x]", date);
            }
            if ((metadata_flags & LS_FILETIME) != 0) {
                printf(" time=");
                print_fat_time(time);
                printf("[0x%04x]", time);
            }
            if ((metadata_flags & LS_ATTRIBUTE) != 0) {
                printf(" attr=0x%02x", attributes);
            }
            putchar('\n');
        }
        offset += name_length + 1;
    }
    return 0;
}

static int run_ls(struct device_connection *connection, const char *path,
                  uint8_t metadata_flags, size_t block_size,
                  unsigned timeout_ms, bool summary)
{
    unsigned char request[USB_BLOCK_SIZE] = {0};
    unsigned char response[USB_BLOCK_SIZE];
    unsigned char data[USB_BLOCK_SIZE];
    struct listing_result result = {0};
    uint8_t response_error = 0;
    int status = -1;

    printf("\nLS path=");
    print_name((const unsigned char *)path, strlen(path));
    printf(" metadata=0x%02x block=%zu\n", metadata_flags, block_size);

    memcpy(request, "USBA", 4);
    request[4] = USB_OPCODE_LS;
    request[5] = USB_SPACE_FILE;
    request[6] = block_size == 64 ? USB_FLAG_64B_DATA : 0;
    request[7] = metadata_flags;
    memcpy(request + 256, path, strlen(path) + 1);

    if (bulk_write_all(connection->handle, request, sizeof(request), timeout_ms) != 0 ||
        bulk_read_exact(connection->handle, response, sizeof(response), timeout_ms) != 0 ||
        validate_response(response, &response_error) != 0) {
        result.needs_resync = true;
        goto done;
    }
    if (read_be32(response + 252) != 1) {
        fprintf(stderr, "malformed LS response: size is %" PRIu32 ", expected 1\n",
                read_be32(response + 252));
        result.needs_resync = true;
        goto done;
    }

    while (!result.complete && result.blocks < MAX_LISTING_BLOCKS) {
        int parsed;
        if (bulk_read_exact(connection->handle, data, block_size, timeout_ms) != 0) {
            result.needs_resync = true;
            goto done;
        }
        ++result.blocks;
        parsed = parse_listing_block(data, block_size, metadata_flags, summary,
                                     &result);
        if (parsed < 0) {
            goto done;
        }
    }
    if (!result.complete) {
        fprintf(stderr, "listing exceeded %u data blocks\n", MAX_LISTING_BLOCKS);
        result.needs_resync = true;
        goto done;
    }
    if (response_error != 0) {
        fprintf(stderr, "LS returned device error %u\n", response_error);
        goto done;
    }

    printf("PASS: %u entries in %u data block%s\n", result.entries,
           result.blocks, result.blocks == 1 ? "" : "s");
    status = 0;

done:
    if (status != 0) {
        printf("FAIL: %u entries in %u data block%s\n", result.entries,
               result.blocks, result.blocks == 1 ? "" : "s");
    }
    if (result.needs_resync && reset_connection(connection, timeout_ms) != 0) {
        return -2;
    }
    return status;
}

int main(int argc, char **argv)
{
    static const uint8_t default_flags[] = {
        0, LS_FILESIZE, LS_FILEDATE, LS_FILETIME, LS_ATTRIBUTE,
        LS_ALL_METADATA,
    };
    struct options options;
    struct device_connection connection;
    libusb_context *context = NULL;
    const uint8_t *test_flags;
    size_t test_count;
    int parse_result;
    int result;
    int failures = 0;
    size_t i;
    size_t block_index;
    size_t block_sizes[2];
    size_t block_count;
    size_t tests_run = 0;

    parse_result = parse_options(argc, argv, &options);
    if (parse_result > 0) {
        return EXIT_SUCCESS;
    }
    if (parse_result < 0) {
        usage(stderr, argv[0]);
        return EXIT_FAILURE;
    }

    test_flags = options.flags;

    if (options.all_combinations) {
        for (i = 0; i <= LS_ALL_METADATA; ++i) {
            options.flags[i] = (uint8_t)i;
        }
        test_count = LS_ALL_METADATA + 1;
    } else if (options.flag_count != 0) {
        test_count = options.flag_count;
    } else {
        test_flags = default_flags;
        test_count = sizeof(default_flags) / sizeof(default_flags[0]);
    }

    if (options.block_mode == 576) {
        block_sizes[0] = 512;
        block_sizes[1] = 64;
        block_count = 2;
    } else {
        block_sizes[0] = options.block_mode;
        block_count = 1;
    }

    result = libusb_init(&context);
    if (result != 0) {
        fprintf(stderr, "could not initialize libusb: %s\n", usb_error(result));
        return EXIT_FAILURE;
    }
    if (open_device(context, &connection) != 0) {
        close_device(&connection, options.timeout_ms);
        libusb_exit(context);
        return EXIT_FAILURE;
    }
    if (reset_connection(&connection, options.timeout_ms) != 0 ||
        query_info(&connection, options.timeout_ms) != 0) {
        close_device(&connection, options.timeout_ms);
        libusb_exit(context);
        return EXIT_FAILURE;
    }

    for (block_index = 0; block_index < block_count; ++block_index) {
        for (i = 0; i < test_count; ++i) {
            result = run_ls(&connection, options.path, test_flags[i],
                            block_sizes[block_index], options.timeout_ms,
                            options.summary);
            ++tests_run;
            if (result == -2) {
                fprintf(stderr, "connection recovery failed; stopping tests\n");
                ++failures;
                goto finished;
            }
            if (result != 0) {
                ++failures;
            }
        }
    }

finished:
    close_device(&connection, options.timeout_ms);
    libusb_exit(context);
    printf("\nResult: %zu test%s, %d failure%s\n", tests_run,
           tests_run == 1 ? "" : "s", failures,
           failures == 1 ? "" : "s");
    return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
