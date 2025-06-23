using System;
using System.Runtime.InteropServices;
using Microsoft.VisualStudio.Shell;

namespace FlywayProject
{
    [Guid("e346c9d2-8915-4a1e-88db-eadb60a9de11")]
    public class VariableToolWindow : ToolWindowPane
    {
        public VariableToolWindow() : base(null)
        {
            this.Caption = "Flyway Input Window";
            this.Content = new VariableToolWindowControl();
        }
    }
}
