# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.6

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake3

# The command to remove a file.
RM = /usr/bin/cmake3 -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /mp/nas1/fixstars/karl/SIFT3D

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /mp/nas1/fixstars/karl/SIFT3D/build

# Include any dependencies generated for this target.
include sift3d/CMakeFiles/mexsift3D.dir/depend.make

# Include the progress variables for this target.
include sift3d/CMakeFiles/mexsift3D.dir/progress.make

# Include the compile flags for this target's objects.
include sift3d/CMakeFiles/mexsift3D.dir/flags.make

sift3d/CMakeFiles/mexsift3D.dir/sift.c.o: sift3d/CMakeFiles/mexsift3D.dir/flags.make
sift3d/CMakeFiles/mexsift3D.dir/sift.c.o: ../sift3d/sift.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/mp/nas1/fixstars/karl/SIFT3D/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object sift3d/CMakeFiles/mexsift3D.dir/sift.c.o"
	cd /mp/nas1/fixstars/karl/SIFT3D/build/sift3d && /bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/mexsift3D.dir/sift.c.o   -c /mp/nas1/fixstars/karl/SIFT3D/sift3d/sift.c

sift3d/CMakeFiles/mexsift3D.dir/sift.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/mexsift3D.dir/sift.c.i"
	cd /mp/nas1/fixstars/karl/SIFT3D/build/sift3d && /bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /mp/nas1/fixstars/karl/SIFT3D/sift3d/sift.c > CMakeFiles/mexsift3D.dir/sift.c.i

sift3d/CMakeFiles/mexsift3D.dir/sift.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/mexsift3D.dir/sift.c.s"
	cd /mp/nas1/fixstars/karl/SIFT3D/build/sift3d && /bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /mp/nas1/fixstars/karl/SIFT3D/sift3d/sift.c -o CMakeFiles/mexsift3D.dir/sift.c.s

sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.requires:

.PHONY : sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.requires

sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.provides: sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.requires
	$(MAKE) -f sift3d/CMakeFiles/mexsift3D.dir/build.make sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.provides.build
.PHONY : sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.provides

sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.provides.build: sift3d/CMakeFiles/mexsift3D.dir/sift.c.o


# Object files for target mexsift3D
mexsift3D_OBJECTS = \
"CMakeFiles/mexsift3D.dir/sift.c.o"

# External object files for target mexsift3D
mexsift3D_EXTERNAL_OBJECTS =

lib/wrappers/matlab/libmexsift3D.so: sift3d/CMakeFiles/mexsift3D.dir/sift.c.o
lib/wrappers/matlab/libmexsift3D.so: sift3d/CMakeFiles/mexsift3D.dir/build.make
lib/wrappers/matlab/libmexsift3D.so: lib/wrappers/matlab/libmeximutil.so
lib/wrappers/matlab/libmexsift3D.so: /usr/lib64/libm.so
lib/wrappers/matlab/libmexsift3D.so: /usr/local/MATLAB/R2018a/bin/glnxa64/libmex.so
lib/wrappers/matlab/libmexsift3D.so: sift3d/CMakeFiles/mexsift3D.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/mp/nas1/fixstars/karl/SIFT3D/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C shared library ../lib/wrappers/matlab/libmexsift3D.so"
	cd /mp/nas1/fixstars/karl/SIFT3D/build/sift3d && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mexsift3D.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
sift3d/CMakeFiles/mexsift3D.dir/build: lib/wrappers/matlab/libmexsift3D.so

.PHONY : sift3d/CMakeFiles/mexsift3D.dir/build

sift3d/CMakeFiles/mexsift3D.dir/requires: sift3d/CMakeFiles/mexsift3D.dir/sift.c.o.requires

.PHONY : sift3d/CMakeFiles/mexsift3D.dir/requires

sift3d/CMakeFiles/mexsift3D.dir/clean:
	cd /mp/nas1/fixstars/karl/SIFT3D/build/sift3d && $(CMAKE_COMMAND) -P CMakeFiles/mexsift3D.dir/cmake_clean.cmake
.PHONY : sift3d/CMakeFiles/mexsift3D.dir/clean

sift3d/CMakeFiles/mexsift3D.dir/depend:
	cd /mp/nas1/fixstars/karl/SIFT3D/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /mp/nas1/fixstars/karl/SIFT3D /mp/nas1/fixstars/karl/SIFT3D/sift3d /mp/nas1/fixstars/karl/SIFT3D/build /mp/nas1/fixstars/karl/SIFT3D/build/sift3d /mp/nas1/fixstars/karl/SIFT3D/build/sift3d/CMakeFiles/mexsift3D.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : sift3d/CMakeFiles/mexsift3D.dir/depend
