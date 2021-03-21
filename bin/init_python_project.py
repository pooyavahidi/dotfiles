#!/usr/bin/env python3

import urllib.request
import os
import shutil
import pathlib
import subprocess

gitignore_url = 'https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore'

def add_empty_file(file_name):
    open(file_name,'w').close()
    print (f'{file_name} is created.')


def add_gitignore():
    file_name='.gitignore'
    urllib.request.urlretrieve(
        url = gitignore_url,
        filename=file_name
    )
    print (f'{file_name} is created.')

def add_readme():
    add_empty_file('README.md')

def add_requirements():
    add_empty_file('requirements.txt')

def add_tests_dir():
    os.makedirs('tests',exist_ok=True)
    print(f'tests directory is created.')
    add_empty_file('tests/__init__.py')

def add_venv_dir():
    subprocess.run(["python3", "-m", "venv", ".env"])
    print (f'.env directory is created.')

def install_pylint():
    subprocess.run([".env/bin/pip","install", "pylint"])
    print (f'pylint is installed in virtual env.')

def add_vscode_dir():
    os.makedirs('.vscode',exist_ok=True)
    src = pathlib.Path(__file__).parent.joinpath('vscode_launch.json')
    shutil.copyfile(src, '.vscode/launch.json')    
    print(f'.vscode directory is created.')

def init():
    add_gitignore()
    add_readme()
    add_requirements()
    add_tests_dir()
    add_venv_dir()
    install_pylint()
    add_vscode_dir()

if __name__ == "__main__":
    init()
