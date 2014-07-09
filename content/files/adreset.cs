namespace ResetAD {

	using System;
	using System.DirectoryServices;
	using System.Collections;

	using System.Core;
	using System.ComponentModel;
	using System.Configuration;
	using System.Data;
	using System.Web.Services;
	using System.Disgnostics;
	using System.ServerProcess;


	public class ResetAD : System.ServiceProcess.ServiceBase {

		// the URI for the server. should be similiar to:  example.com
		private string URI;
		// the scope to be using. should be similar to: OU=Users,DC=example,DC=com
		private string Scope;

		private System.ComponentModel.Container components;

		private ResetAD(string newURI, string newScope) {
			InitializeComponent();
			URI = newURI;
			Scope = newScope;		
		}

		public VerifyADConnection() {
			DirectoryEntry someEntry = new DirectoryEntry("LDAP://" 
					+ URI + "," + Scope);
			if (someEntry = null) {
				return false;
			} else {
				return true;
			}
		}

		//returns true if we succeed, false otherwise
		public ResetADPassword(string targetDN, string newPassword) {

			DirectoryEntry userEntry = new DirectoryEntry("LDAP://" + URI + "/DN=" 
					+ targetDN +"," + Scope);
			userEntry.usePropertyCache(true);

			if (userEntry != null) {
				userEntry.Properties["unicodePwd"].Value = newPassword;
				value = (int)  userEntry.Properties["userAccessControl"].Value;
				userEntry.Properties["userAccessControl"].Value
					= value | !ADS_UF_LOCKOUT;
				if (userEntry.CommitChanges()) {
					return true;
				}
			}  
			return false;
		}

		static void Main(string[] args) {

			if (args.Length < 2) {
				//need URI and Scope paramaters
			} 
			string newURI = args[0];
			string newScope = args[1];

			ResetAD testResetAD = new ResetAD(newURI, newScope);
			if (testResetAD.VerifyADConnection()) {		
				System.ServiceProcess.ServiceBase[] ServicesToRun;
				ServicesToRun = new System.ServiceProcess.Servicebase[] {
					new ResetAD(newURI, newScope) };
				System.ServiceProcess.ServiceBase.Run(ServicesToRun);
			} else {
				//failed to connect to server, retry paramaters
			}
		}

		private	void InitializeComponent() {
			components = new System.ComponentModel.Container();
			this.ServiceName = "ResetAD";
		}

		protected override void OnStart(string[] args) {
			//listen for connection from client app, fire off
		}

		protected override void OnStop() {

		}
	}
}
