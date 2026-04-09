import { INestApplication } from "@nestjs/common";
import { Test } from "@nestjs/testing";
import request from "supertest";

import { AppModule } from "../src/app.module";

describe("AppController (e2e)", () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it("/ (GET)", () =>
    request(app.getHttpServer()).get("/").expect(200).expect("Hello Backend!"));

  it("rejects SQL injection payloads with 400", () =>
    request(app.getHttpServer())
      .get("/users/search")
      .query({
        page: 1,
        limit: 10,
        sort: '[{"name":"ASC"}]',
        filter:
          '[{"key":"name","operation":"like","value":"\' OR 1=1 --"}]',
      })
      .expect(400)
      .expect({
        statusCode: 400,
        message: "Potential SQL injection payload detected",
      }));
});
