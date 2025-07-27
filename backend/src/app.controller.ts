import { Controller, Get } from "@nestjs/common";
import { AppService } from "./app.service";
import * as https from "https";
import * as url from "url";
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }
  @Get("connectivity")
  async testOutboundConnectivity() {
    const testUrls = [
      "https://www.microsoft.com",
      "https://canadacentral-1.in.applicationinsights.azure.com",
      "https://canadacentral.livediagnostics.monitor.azure.com",
    ];

    const results = [];

    for (const testUrl of testUrls) {
      try {
        const parsedUrl = new url.URL(testUrl);
        const result = await new Promise((resolve) => {
          const req = https.request(
            {
              hostname: parsedUrl.hostname,
              port: 443,
              path: "/",
              method: "HEAD",
              timeout: 5000,
            },
            (res) => {
              resolve({
                url: testUrl,
                status: "Success",
                statusCode: res.statusCode,
                reachable: true,
              });
            },
          );

          req.on("error", (e) => {
            resolve({
              url: testUrl,
              status: "Failed",
              error: e.message,
              reachable: false,
            });
          });

          req.on("timeout", () => {
            resolve({
              url: testUrl,
              status: "Timeout",
              error: "Request timed out",
              reachable: false,
            });
            req.destroy();
          });

          req.end();
        });

        results.push(result);
      } catch (error) {
        results.push({
          url: testUrl,
          status: "Error",
          error: error.message,
          reachable: false,
        });
      }
    }

    console.log("Connectivity test results:", JSON.stringify(results, null, 2));
    return { connectivityTest: results };
  }
}
