import glob
import jinja2
import pathlib
import os


def replace(file_path: str, subst: dict[str, str]):
    """
    Replace all {{pattern}} in file with given value subst.

    :param file_path: The path to the file to process.
    :param subst: A dictionary with keys as the pattern names without curly braces,
                  and values as the text to substitute in.
    """
    # Read the content of the file
    try:
        with open(file_path, "r") as file:
            content = file.read()
    except UnicodeDecodeError as e:
        return

    # Create a Jinja Template from the content
    template = jinja2.Template(content)

    # Render the template with the substitution dictionary
    rendered_content = template.render(subst)
    # print(rendered_content)
    # Write the modified content back to the file
    with open(file_path, "w") as file:
        file.write(rendered_content)


def replace_in_files(files: list[str], subst: dict[str, str]):
    """
    Replace all {{pattern}} in all files in the list with given value subst.

    :param files: A list of file paths to process.
    :param subst: A dictionary with keys as the pattern names without curly braces,
                  and values as the text to substitute in.
    """
    # Iterate over the list of files
    for file_path in files:
        try:
            replace(file_path, subst)
        except jinja2.exceptions.UndefinedError as e:
            print(f"Error: {e}")
        print(f"Replacing: {file_path}")


dir_path = os.getenv("DIR_PATH", "./assets/fake-crypto-webapp-project-main")
ACCOUNT_ID = os.getenv("ACCOUNT_ID", "{{ACCOUNT_ID_NOT_FOUND}}")

print(f"Account: {ACCOUNT_ID}")

replace_in_files(
    files=[
        i
        for i in glob.glob(f"{dir_path}/**/*", recursive=True)
        if pathlib.Path(i).is_file()
    ],
    subst={
        "ACCOUNT_ID": ACCOUNT_ID,
        "AWS_REGION": "us-east-1",
        "REPO_NAME": "fake-crypto-webapp"
    },
)
