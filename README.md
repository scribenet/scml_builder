scml_builder
============

For outputting ScML lists (DTDs, templates, etc.) from a central yaml file (elements.yml). As much as possible, we should manage the expressions of the ScML tag list from a single master file.

## From the Repository

This assumes you have a modern version of Ruby installed. If not, consult the internet.

- Clone the repository.
- In the repository, run `bundle install`

It's not set up and ready. The kinds of output it can produce are listed in "list_types.yml".

`scml_builder` takes two arguments: the output type (from the list types in the file mentioned) and, optionally, an output location. If no output location is provided, the output will be written into the main repo directory. 

Using "scml_dtd" as the type and "/home/frank/scml_stuff/" as the directory:

`bundle exec scml_builder scml_dtd /home/frank/scml_stuff`

This produces a copy of the DTD from the current elements list, located at "/home/frank/scml_stuff/scml.dtd".
