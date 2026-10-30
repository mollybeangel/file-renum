package main

import "core:flags"
import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strings"

UPPER_CASE_START :: 65
UPPER_CASE_END :: 90

LOWER_CASE_START :: 97
LOWER_CASE_END :: 122

UserOptions :: struct {
	path:   string,
	prefix: string,
}

generate_name :: proc() -> string {
	builder: strings.Builder
	defer strings.builder_destroy(&builder)

	name_length := rand.int_range(32, 64)

	for i in 0 ..< name_length {
		ch: int = 0

		if rand.int_range(1, 3) == 1 {
			ch = rand.int_range(UPPER_CASE_START, UPPER_CASE_END)
		} else {
			ch = rand.int_range(LOWER_CASE_START, LOWER_CASE_END)
		}

		strings.write_byte(&builder, cast(u8)ch)
	}

	result := strings.to_string(builder)

	return result
}

rename_files :: proc(path: string, prefix_intent: string) {
	found_item := false
	prefix: string
	dir_path := path if len(path) > 0 else "."
	dir_format := "/" if len(path) > 0 else ""

	if len(prefix_intent) == 0 {
		prefix = "jpg"
	} else {
		prefix = prefix_intent

		buf := [8]u8{}
		fmt.printf("Are you sure your prefix is %s. Type yes or no: ",prefix)

		total_read, err := os.read(os.stdin, buf[:])

		if err != nil {
			panic("Failed to confirm prefix from you. Something went wrong")
		}

		confirm_string := string(buf[:total_read])

		if !strings.has_prefix(strings.trim(strings.to_lower(confirm_string),""), "yes") {
			fmt.println("INFO: Cancelled rename process due to prefix denial.")
			return
		}
	}

	files, err := os.read_all_directory_by_path(path if len(path) > 0 else ".", context.allocator)

	if err != nil {
		fmt.printf("ERROR: Failed to read '%s' directory.\n",path if len(path) > 0 else ".")
		return
	}

	defer os.file_info_slice_delete(files, context.allocator)

	for file in files {
		if strings.has_prefix(file.name, prefix) {
			found_item = true

			for i in 0 ..< 3 {
				new_name := strings.concatenate(
					{path,dir_format,generate_name(), strings.concatenate({".", prefix})},
				)

				rename_err := os.rename(strings.concatenate({path,dir_format,file.name}), new_name)

				if rename_err == os.General_Error.Invalid_Path {
					fmt.printf("WARNING: Failed to renamed '%s%s%s' to '%s'\n",path,dir_format,file.name,new_name)
				}

				if rename_err == nil {
					fmt.printf("INFO: Successfully renamed '%s%s%s' to '%s'\n",path,dir_format,file.name,new_name)
					break
				}
			}
		}
	}

	if !found_item {
		fmt.println("INFO: Nothing to rename")
	}
}

main :: proc() {
	user_opts: UserOptions
	flags.parse_or_exit(&user_opts, os.args, .Unix)
	rename_files(user_opts.path,user_opts.prefix)
}
