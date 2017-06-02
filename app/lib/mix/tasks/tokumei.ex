defmodule Mix.Tasks.Tokumei.New do
  use Mix.Task
  @shortdoc "Shiny new Tokumei application. :-)"
  @moduledoc """
  ```
  mix tokumei.new <app_dir>
  ```
  """

  def run([]) do
    Mix.Tasks.Help.run ["tokumei.new"]
  end

  @safe_app_name ~r/^[a-z][\w_]*$/
  def run([project_path]) do
    app_name = project_path
    app_name =~ @safe_app_name
    app_module = Macro.camelize(app_name)
    # if Mix.shell.yes?("continue?") do
    if true do
      File.mkdir_p!(project_path)
      |> IO.inspect
      File.cd!(project_path, fn() ->
        generate(app_name, app_module, [app_name: app_name, app_module: app_module])
      end)
      |> IO.inspect
      """
      Your Tokumei project was created successfully.

      Get started:

          cd #{project_path}
          mix deps.get
          iex -S mix

      View on localhost:8080
      """
      |> String.trim_trailing
      |> Mix.shell.info
    end
  end

  template_location = Path.join(__DIR__, "./**/*")
  template_files = Path.wildcard(template_location, match_dot: true)
  templates = for template_file <- template_files do
    case File.read(template_file) do
      {:ok, template} ->
        path = Path.relative_to(template_file, Path.expand("./template", __DIR__))
        case String.split(path, ~r/\.eex$/) do
          [path, ""] ->
            {:eex, path, template}
          [path] ->
            {:raw, path, template}
        end
      {:error, :eisdir} ->
        :nope
    end
  end
  @templates templates

  defp generate(app_name, app_module, bindings) do
    for template <- @templates do
      case template do
        :nope ->
          :nope
        {:eex, path, template} ->
          path = String.replace(path, "app_name", app_name)
          File.mkdir_p!(Path.dirname(path))
          contents = EEx.eval_string(template, bindings)
          File.write!(path, contents)
        {:raw, path, contents} ->
          path = String.replace(path, "app_name", app_name)
          File.mkdir_p!(Path.dirname(path))
          File.write!(path, contents)
      end
    end
  end
end
