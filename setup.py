from setuptools import setup, find_packages

# Function to read the requirements from requirements.txt
def read_requirements():
    with open('requirements.txt') as req_file:
        return req_file.readlines()


setup(
    name="data_science_project",
    version="0.1",
    packages=find_packages(),
    install_requires=read_requirements(),
)