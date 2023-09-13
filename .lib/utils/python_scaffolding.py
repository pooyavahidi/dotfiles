import os
import urllib.request
import shutil
import pathlib
import subprocess


def add_gitignore():
    file_name = ".gitignore"
    urllib.request.urlretrieve(
        url="https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore",
        filename=file_name,
    )
    print(f"{file_name} is created.")


def add_readme():
    add_empty_file("README.md")


def add_requirements():
    copy_file("requirements.txt")


def install_requirements():
    # Upgrade pip first
    subprocess.run([".env/bin/pip", "install", "--upgrade", "pip"], check=True)
    subprocess.run(
        [".env/bin/pip", "install", "-r", "requirements.txt"], check=True
    )
    print("libraries from the requirements are installed in the virtual env.")


def add_tests_dir():
    os.makedirs("tests", exist_ok=True)
    print("tests directory is created.")
    add_empty_file("tests/__init__.py")


def add_venv_dir():
    subprocess.run(["python3", "-m", "venv", ".env"], check=True)
    print(".env directory is created.")


def add_vscode_dir():
    os.makedirs(".vscode", exist_ok=True)
    copy_file("vscode_launch.json", ".vscode/launch.json")
    print(".vscode directory is created.")


def copy_file(file_name, dest=None):
    src = (
        pathlib.Path(__file__)
        .parent.joinpath("python_scaffolding_templates")
        .joinpath(file_name)
    )
    if not dest:
        dest = file_name

    shutil.copyfile(src, dest)


def add_empty_file(file_name):
    open(file_name, "w").close()
    print(f"{file_name} is created.")


def init():
    add_gitignore()
    add_readme()
    add_requirements()
    add_tests_dir()
    add_venv_dir()
    install_requirements()
    add_vscode_dir()


if __name__ == "__main__":
    init()
