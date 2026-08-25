# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
# Problems with imports? Could try `export PYTHONPATH=$PYTHONPATH:`pwd`` from root project dir...

import os
import sys

sys.path.insert(0, os.path.abspath('../..'))
# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'planarity'
copyright = '2026, John M. Boyer, Wanda B.K. Boyer, Aric Hagberg'
author = 'John M. Boyer, Wanda B.K. Boyer, Aric Hagberg'
release = '1.0.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

# Add any Sphinx extension module names here, as strings
extensions = [
    'sphinx.ext.apidoc',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
]

templates_path = ['_templates']
exclude_patterns = []

apidoc_modules = [
    {
        'path': '../../planarity',
        'destination': 'api',
        # This produces the Python docs for the full API from Python
        'exclude_patterns': ['**/classic*'],
        'separate_modules': True,
    },
]

autodoc_default_options = {
    'members': True,
    'undoc-members': True,
    'special-members': '__cinit__, __dealloc__',
    'exclude-members': '__weakref__, __reduce_cython__, __setstate_cython__',
}

autosummary_generate = True # Allows autosummary to generate stub files
autoclass_content = "both"  # Add __init__ doc (ie. params) to class summaries
html_show_sourcelink = False  # Remove 'view source code' from top of page (for html, not python)
autodoc_inherit_docstrings = True  # If no docstring, inherit from base class
set_type_checking_flag = True  # Enable 'expensive' imports for sphinx_autodoc_typehints
nbsphinx_allow_errors = True  # Continue through Jupyter errors
#autodoc_typehints = "description" # Sphinx-native method. Not as good as sphinx_autodoc_typehints
add_module_names = False # Remove namespaces from class/method signatures

# Napoleon settings
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = True
napoleon_include_private_with_doc = True
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = False
napoleon_use_admonition_for_notes = False
napoleon_use_admonition_for_references = False
napoleon_use_ivar = False
napoleon_use_param = True
napoleon_use_rtype = True
napoleon_preprocess_types = False
napoleon_type_aliases = None
napoleon_attr_annotations = True

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

html_theme = 'alabaster'
html_static_path = ['_static']
