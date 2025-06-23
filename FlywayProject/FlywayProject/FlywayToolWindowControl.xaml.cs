using System;
using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;

namespace FlywayProject
{
    public partial class VariableToolWindowControl : UserControl
    {
        public VariableToolWindowControl()
        {
            InitializeComponent();
        }

        private void OnSubmitClicked(object sender, RoutedEventArgs e)
        {
            string flywayDir = Var1TextBox.Text.Trim();         // Flyway project directory
            string source = Var2TextBox.Text.Trim();            // Comparison source env
            string target = Var3TextBox.Text.Trim();            // Target deploy env
            string customParams = Var4TextBox.Text.Trim();      // Additional params (optional)

            if (string.IsNullOrWhiteSpace(flywayDir) || !Directory.Exists(flywayDir))
            {
                MessageBox.Show("Flyway directory is invalid or does not exist.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            string workingDir = flywayDir;
            string scriptFilename = "migration.sql"; // You can make this configurable if needed

            string flywayExe = "flyway"; // rely on PATH


            string commandArgs =
                $"prepare deploy " +
                $"-prepare.source={source} " +
                $"-prepare.target={target} " +
                $"-environment={target} " +
                $"-environments.{target}.user=REPLACE_ME " +
                $"-environments.{target}.password=REPLACE_ME " +
                $"-prepare.scriptFilename=\"{workingDir}\\Artifact\\{scriptFilename}\" " +
                $"-deploy.scriptFilename=\"{workingDir}\\Artifact\\{scriptFilename}\" " +
                $"-prepare.force=true " +
                $"-configFiles=\"{workingDir}\\flyway.toml\" " +
                $"-schemaModelLocation=\"{workingDir}\\schema-model\" " +
                $"-cleanDisabled=false " +
                $"{customParams}";

            try
            {
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo("flyway") 
                    {                     
                        Arguments = $"{commandArgs}"                  
                    }

                };

                process.OutputDataReceived += (s, ea) => Debug.WriteLine(ea.Data);
                process.ErrorDataReceived += (s, ea) => Debug.WriteLine("ERROR: " + ea.Data);

                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.WaitForExit();

                MessageBox.Show("Flyway command launched.", "Info", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to run Flyway:\n{ex.Message}", "Execution Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }
    }
}
