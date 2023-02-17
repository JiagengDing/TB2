from solcx import compile_files

def compile_sol(file_path):
    
    compile = compile_files([file_path], output_values=["abi", "bin"])

    return list(compile.values())[0]

def compile_sol_to_file(file_path, output_file_path):

    compile = compile_sol(file_path)

    with open(output_file_path, "w") as f:
        f.write(str(compile))


#compile_sol_to_file("test.sol", "test/out.txt")